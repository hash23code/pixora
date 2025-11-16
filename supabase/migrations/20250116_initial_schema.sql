-- ==================== INITIAL SCHEMA FOR SUPABASE ====================
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==================== ENUMS ====================
CREATE TYPE user_role AS ENUM ('user', 'admin');
CREATE TYPE project_role AS ENUM ('owner', 'editor', 'viewer');
CREATE TYPE transaction_type AS ENUM ('purchase', 'deduction', 'refund', 'bonus');
CREATE TYPE transaction_status AS ENUM ('pending', 'completed', 'failed');
CREATE TYPE asset_type AS ENUM ('image', 'video', 'audio', 'svg', 'document');
CREATE TYPE subscription_status AS ENUM ('active', 'canceled', 'past_due', 'trialing');
CREATE TYPE ai_tool AS ENUM (
  'logo-generator', 'social-post', 'copywriter', 'mockup-generator', 'image-upscaler',
  'video-generator', 'audio-generator', 'ad-campaign', 'background-remover', 'style-transfer',
  'face-swap', 'video-upscaler', 'text-to-speech', 'music-generator', 'voiceover'
);
CREATE TYPE job_status AS ENUM ('pending', 'processing', 'completed', 'failed');
CREATE TYPE ad_format AS ENUM ('social', 'display', 'video', 'story', 'carousel');

-- ==================== PROFILES (extends auth.users) ====================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  avatar VARCHAR(512),
  role user_role DEFAULT 'user' NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, created_at)
  VALUES (NEW.id, NOW());

  -- Also create tokens balance
  INSERT INTO public.tokens_balance (user_id, balance)
  VALUES (NEW.id, 100); -- 100 free tokens

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ==================== PROJECTS ====================
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own projects"
  ON projects FOR SELECT
  USING (auth.uid() = owner_id OR EXISTS (
    SELECT 1 FROM collaborators
    WHERE project_id = projects.id AND user_id = auth.uid()
  ));

CREATE POLICY "Users can insert own projects"
  ON projects FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update own projects"
  ON projects FOR UPDATE
  USING (auth.uid() = owner_id);

CREATE POLICY "Owners can delete own projects"
  ON projects FOR DELETE
  USING (auth.uid() = owner_id);

CREATE INDEX idx_projects_owner_id ON projects(owner_id);
CREATE INDEX idx_projects_created_at ON projects(created_at);

-- ==================== BOARDS ====================
CREATE TABLE boards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID UNIQUE NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  yjs_snapshot BYTEA,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE boards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can access boards of their projects"
  ON boards FOR ALL
  USING (EXISTS (
    SELECT 1 FROM projects
    WHERE projects.id = boards.project_id
    AND (projects.owner_id = auth.uid() OR EXISTS (
      SELECT 1 FROM collaborators
      WHERE collaborators.project_id = projects.id
      AND collaborators.user_id = auth.uid()
    ))
  ));

-- Auto-create board when project is created
CREATE OR REPLACE FUNCTION create_board_for_project()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO boards (project_id) VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_board
  AFTER INSERT ON projects
  FOR EACH ROW
  EXECUTE FUNCTION create_board_for_project();

-- ==================== REVISIONS ====================
CREATE TABLE revisions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
  commit_message TEXT,
  snapshot BYTEA NOT NULL,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE revisions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view revisions of their boards"
  ON revisions FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM boards
    JOIN projects ON boards.project_id = projects.id
    WHERE boards.id = revisions.board_id
    AND (projects.owner_id = auth.uid() OR EXISTS (
      SELECT 1 FROM collaborators
      WHERE collaborators.project_id = projects.id
      AND collaborators.user_id = auth.uid()
    ))
  ));

CREATE INDEX idx_revisions_board_id ON revisions(board_id);
CREATE INDEX idx_revisions_created_at ON revisions(created_at);

-- ==================== ASSETS ====================
CREATE TABLE assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  storage_path VARCHAR(1024) NOT NULL, -- Supabase Storage path
  type asset_type NOT NULL,
  metadata JSONB DEFAULT '{}',
  size INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE assets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view assets of their projects"
  ON assets FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM projects
    WHERE projects.id = assets.project_id
    AND (projects.owner_id = auth.uid() OR EXISTS (
      SELECT 1 FROM collaborators
      WHERE collaborators.project_id = projects.id
      AND collaborators.user_id = auth.uid()
    ))
  ));

CREATE INDEX idx_assets_project_id ON assets(project_id);
CREATE INDEX idx_assets_type ON assets(type);

-- ==================== TOKEN BALANCES ====================
CREATE TABLE tokens_balance (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  balance INTEGER DEFAULT 0 NOT NULL CHECK (balance >= 0),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE tokens_balance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own balance"
  ON tokens_balance FOR SELECT
  USING (auth.uid() = user_id);

-- ==================== TRANSACTIONS ====================
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  type transaction_type NOT NULL,
  status transaction_status DEFAULT 'pending' NOT NULL,
  metadata JSONB DEFAULT '{}',
  idempotency_key VARCHAR(255) UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_idempotency_key ON transactions(idempotency_key);

-- ==================== SUBSCRIPTIONS ====================
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stripe_subscription_id VARCHAR(255) UNIQUE,
  stripe_customer_id VARCHAR(255),
  plan_id VARCHAR(50) NOT NULL,
  status subscription_status DEFAULT 'active',
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  tokens_allowance INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  canceled_at TIMESTAMPTZ
);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscription"
  ON subscriptions FOR SELECT
  USING (auth.uid() = user_id);

-- ==================== COLLABORATORS ====================
CREATE TABLE collaborators (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role project_role DEFAULT 'viewer' NOT NULL,
  invited_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(project_id, user_id)
);

ALTER TABLE collaborators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view collaborators of their projects"
  ON collaborators FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM projects
    WHERE projects.id = collaborators.project_id
    AND (projects.owner_id = auth.uid() OR EXISTS (
      SELECT 1 FROM collaborators c2
      WHERE c2.project_id = projects.id AND c2.user_id = auth.uid()
    ))
  ));

CREATE INDEX idx_collaborators_project_id ON collaborators(project_id);
CREATE INDEX idx_collaborators_user_id ON collaborators(user_id);

-- ==================== AI JOBS ====================
CREATE TABLE ai_jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  tool ai_tool NOT NULL,
  prompt TEXT NOT NULL,
  parameters JSONB DEFAULT '{}',
  status job_status DEFAULT 'pending' NOT NULL,
  progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  estimated_tokens INTEGER NOT NULL,
  transaction_id UUID REFERENCES transactions(id),
  result JSONB,
  error TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
);

ALTER TABLE ai_jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own jobs"
  ON ai_jobs FOR SELECT
  USING (auth.uid() = user_id);

CREATE INDEX idx_ai_jobs_user_id ON ai_jobs(user_id);
CREATE INDEX idx_ai_jobs_status ON ai_jobs(status);

-- ==================== AD CAMPAIGNS ====================
CREATE TABLE ad_campaigns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  format ad_format NOT NULL,
  target_audience JSONB DEFAULT '{}',
  brand_guidelines JSONB DEFAULT '{}',
  script TEXT,
  assets JSONB DEFAULT '[]', -- Array of asset IDs
  status VARCHAR(50) DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE ad_campaigns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own campaigns"
  ON ad_campaigns FOR ALL
  USING (auth.uid() = user_id);

CREATE INDEX idx_ad_campaigns_user_id ON ad_campaigns(user_id);
CREATE INDEX idx_ad_campaigns_project_id ON ad_campaigns(project_id);

-- ==================== TRIGGERS ====================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_boards_updated_at
  BEFORE UPDATE ON boards
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tokens_balance_updated_at
  BEFORE UPDATE ON tokens_balance
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ==================== FUNCTIONS ====================

-- Function to reserve tokens (ACID-safe)
CREATE OR REPLACE FUNCTION reserve_tokens(
  p_user_id UUID,
  p_amount INTEGER,
  p_metadata JSONB DEFAULT '{}'::JSONB,
  p_idempotency_key TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_balance INTEGER;
  v_transaction_id UUID;
BEGIN
  -- Check idempotency
  IF p_idempotency_key IS NOT NULL THEN
    SELECT id INTO v_transaction_id
    FROM transactions
    WHERE idempotency_key = p_idempotency_key;

    IF FOUND THEN
      RETURN v_transaction_id;
    END IF;
  END IF;

  -- Lock and check balance
  SELECT balance INTO v_balance
  FROM tokens_balance
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF v_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient tokens: have %, need %', v_balance, p_amount;
  END IF;

  -- Create pending transaction
  INSERT INTO transactions (user_id, amount, type, status, metadata, idempotency_key)
  VALUES (p_user_id, -p_amount, 'deduction', 'pending', p_metadata, p_idempotency_key)
  RETURNING id INTO v_transaction_id;

  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql;

-- Function to complete token deduction
CREATE OR REPLACE FUNCTION complete_token_deduction(p_transaction_id UUID)
RETURNS VOID AS $$
DECLARE
  v_user_id UUID;
  v_amount INTEGER;
  v_status transaction_status;
BEGIN
  -- Get transaction details
  SELECT user_id, amount, status INTO v_user_id, v_amount, v_status
  FROM transactions
  WHERE id = p_transaction_id
  FOR UPDATE;

  IF v_status != 'pending' THEN
    RAISE EXCEPTION 'Transaction % is not pending (status: %)', p_transaction_id, v_status;
  END IF;

  -- Deduct tokens
  UPDATE tokens_balance
  SET balance = balance + v_amount -- v_amount is negative for deduction
  WHERE user_id = v_user_id;

  -- Mark transaction completed
  UPDATE transactions
  SET status = 'completed', completed_at = NOW()
  WHERE id = p_transaction_id;
END;
$$ LANGUAGE plpgsql;

-- Function to refund tokens
CREATE OR REPLACE FUNCTION refund_tokens(p_transaction_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE transactions
  SET status = 'failed', completed_at = NOW()
  WHERE id = p_transaction_id;
END;
$$ LANGUAGE plpgsql;

COMMIT;
