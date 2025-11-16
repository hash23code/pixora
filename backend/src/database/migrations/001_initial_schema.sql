-- ==================== EXTENSIONS ====================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==================== ENUMS ====================

CREATE TYPE user_role AS ENUM ('user', 'admin');
CREATE TYPE project_role AS ENUM ('owner', 'editor', 'viewer');
CREATE TYPE transaction_type AS ENUM ('purchase', 'deduction', 'refund', 'bonus');
CREATE TYPE transaction_status AS ENUM ('pending', 'completed', 'failed');
CREATE TYPE asset_type AS ENUM ('image', 'svg', 'video', 'document');
CREATE TYPE subscription_status AS ENUM ('active', 'canceled', 'past_due', 'trialing');
CREATE TYPE ai_tool AS ENUM ('logo-generator', 'social-post', 'copywriter', 'mockup-generator', 'image-upscaler');
CREATE TYPE job_status AS ENUM ('pending', 'processing', 'completed', 'failed');

-- ==================== USERS ====================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255), -- NULL si OAuth2 only
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    avatar VARCHAR(512),
    role user_role DEFAULT 'user' NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- ==================== OAUTH ACCOUNTS ====================

CREATE TABLE oauth_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL, -- 'google', 'github', etc.
    provider_account_id VARCHAR(255) NOT NULL,
    access_token TEXT,
    refresh_token TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(provider, provider_account_id)
);

CREATE INDEX idx_oauth_user_id ON oauth_accounts(user_id);
CREATE INDEX idx_oauth_provider ON oauth_accounts(provider);

-- ==================== REFRESH TOKENS ====================

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(512) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);

-- ==================== PROJECTS ====================

CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    settings JSONB DEFAULT '{}', -- {brand: {colors: [], fonts: []}, ...}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_projects_owner_id ON projects(owner_id);
CREATE INDEX idx_projects_created_at ON projects(created_at);

-- ==================== BOARDS ====================

CREATE TABLE boards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID UNIQUE NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    yjs_snapshot BYTEA, -- Yjs document encoded
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_boards_project_id ON boards(project_id);

-- ==================== REVISIONS (Board History) ====================

CREATE TABLE revisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
    commit_message TEXT,
    snapshot BYTEA NOT NULL,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_revisions_board_id ON revisions(board_id);
CREATE INDEX idx_revisions_created_at ON revisions(created_at);

-- ==================== ASSETS ====================

CREATE TABLE assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    url VARCHAR(1024) NOT NULL,
    type asset_type NOT NULL,
    metadata JSONB DEFAULT '{}', -- {width, height, format, size, etc.}
    size INTEGER, -- bytes
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_assets_project_id ON assets(project_id);
CREATE INDEX idx_assets_created_by ON assets(created_by);
CREATE INDEX idx_assets_created_at ON assets(created_at);
CREATE INDEX idx_assets_type ON assets(type);

-- ==================== TOKEN BALANCES ====================

CREATE TABLE tokens_balance (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    balance INTEGER DEFAULT 0 NOT NULL CHECK (balance >= 0),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tokens_balance_user_id ON tokens_balance(user_id);

-- ==================== TRANSACTIONS ====================

CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL, -- Positive for purchase/bonus, negative for deduction
    type transaction_type NOT NULL,
    status transaction_status DEFAULT 'pending' NOT NULL,
    metadata JSONB DEFAULT '{}', -- {jobId, stripePaymentIntent, etc.}
    idempotency_key VARCHAR(255) UNIQUE, -- Pour éviter double deduction
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_created_at ON transactions(created_at);
CREATE INDEX idx_transactions_idempotency_key ON transactions(idempotency_key);

-- ==================== SUBSCRIPTIONS ====================

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    stripe_subscription_id VARCHAR(255) UNIQUE,
    stripe_customer_id VARCHAR(255),
    plan_id VARCHAR(50) NOT NULL, -- 'free', 'pro', 'enterprise'
    status subscription_status DEFAULT 'active',
    current_period_start TIMESTAMP WITH TIME ZONE,
    current_period_end TIMESTAMP WITH TIME ZONE,
    tokens_allowance INTEGER DEFAULT 0, -- Tokens mensuels inclus
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    canceled_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_stripe_customer_id ON subscriptions(stripe_customer_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);

-- ==================== COLLABORATORS ====================

CREATE TABLE collaborators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role project_role DEFAULT 'viewer' NOT NULL,
    invited_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, user_id)
);

CREATE INDEX idx_collaborators_project_id ON collaborators(project_id);
CREATE INDEX idx_collaborators_user_id ON collaborators(user_id);

-- ==================== AI JOBS ====================

CREATE TABLE ai_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    tool ai_tool NOT NULL,
    prompt TEXT NOT NULL,
    parameters JSONB DEFAULT '{}',
    status job_status DEFAULT 'pending' NOT NULL,
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    estimated_tokens INTEGER NOT NULL,
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
    result JSONB, -- {assetIds: [...], metadata: {...}}
    error TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_ai_jobs_user_id ON ai_jobs(user_id);
CREATE INDEX idx_ai_jobs_project_id ON ai_jobs(project_id);
CREATE INDEX idx_ai_jobs_status ON ai_jobs(status);
CREATE INDEX idx_ai_jobs_created_at ON ai_jobs(created_at);

-- ==================== INVITATIONS ====================

CREATE TABLE invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    role project_role DEFAULT 'viewer' NOT NULL,
    token VARCHAR(512) UNIQUE NOT NULL,
    invited_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    accepted_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_invitations_project_id ON invitations(project_id);
CREATE INDEX idx_invitations_email ON invitations(email);
CREATE INDEX idx_invitations_token ON invitations(token);

-- ==================== AUDIT LOGS (Optional, Enterprise) ====================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL, -- 'user.login', 'project.create', etc.
    resource_type VARCHAR(50), -- 'project', 'asset', etc.
    resource_id UUID,
    metadata JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- ==================== TRIGGERS ====================

-- Auto-update updated_at on UPDATE
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_boards_updated_at BEFORE UPDATE ON boards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tokens_balance_updated_at BEFORE UPDATE ON tokens_balance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-create tokens_balance on user creation
CREATE OR REPLACE FUNCTION create_tokens_balance_for_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO tokens_balance (user_id, balance)
    VALUES (NEW.id, 100); -- 100 tokens gratuits à l'inscription
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_tokens_balance AFTER INSERT ON users
    FOR EACH ROW EXECUTE FUNCTION create_tokens_balance_for_user();

-- Auto-create board when project is created
CREATE OR REPLACE FUNCTION create_board_for_project()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO boards (project_id)
    VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_board AFTER INSERT ON projects
    FOR EACH ROW EXECUTE FUNCTION create_board_for_project();

-- ==================== SEED DATA (Optional for dev) ====================

-- Admin user (password: Admin123!)
INSERT INTO users (id, email, password_hash, first_name, last_name, role, email_verified)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'admin@pixora.com',
    '$2b$10$CwTycUXWue0Thq9StjUM0uJ8/H8V8WPL.KZYz9vXGdJ3K/9/jNj4G', -- hashed "Admin123!"
    'Admin',
    'Pixora',
    'admin',
    TRUE
);

-- Test user (password: Test123!)
INSERT INTO users (id, email, password_hash, first_name, last_name, role, email_verified)
VALUES (
    '00000000-0000-0000-0000-000000000002',
    'test@pixora.com',
    '$2b$10$9uYQYmI/8AO7nKJPjvHNpOG.6v8Z9Xv3jQm8wKqG4fZ9kQm4nKJPj', -- hashed "Test123!"
    'Test',
    'User',
    'user',
    TRUE
);

-- Demo project
INSERT INTO projects (id, owner_id, title, description, settings)
VALUES (
    '00000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000002',
    'Demo Project',
    'A demo project to showcase Pixora features',
    '{"brand": {"colors": ["#FF5733", "#3498DB", "#2ECC71"], "fonts": ["Inter", "Playfair Display"]}}'
);

COMMIT;
