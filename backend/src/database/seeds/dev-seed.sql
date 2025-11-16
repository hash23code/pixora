-- ==================== DEVELOPMENT SEED DATA ====================
-- Ce fichier ajoute des données de test pour le développement local
-- NE PAS EXÉCUTER EN PRODUCTION

-- ==================== USERS ====================

INSERT INTO users (id, email, password_hash, first_name, last_name, role, email_verified)
VALUES
    -- Password for all: Test123!
    ('10000000-0000-0000-0000-000000000001', 'alice@example.com', '$2b$10$9uYQYmI/8AO7nKJPjvHNpOG.6v8Z9Xv3jQm8wKqG4fZ9kQm4nKJPj', 'Alice', 'Designer', 'user', TRUE),
    ('10000000-0000-0000-0000-000000000002', 'bob@example.com', '$2b$10$9uYQYmI/8AO7nKJPjvHNpOG.6v8Z9Xv3jQm8wKqG4fZ9kQm4nKJPj', 'Bob', 'Marketer', 'user', TRUE),
    ('10000000-0000-0000-0000-000000000003', 'charlie@example.com', '$2b$10$9uYQYmI/8AO7nKJPjvHNpOG.6v8Z9Xv3jQm8wKqG4fZ9kQm4nKJPj', 'Charlie', 'Developer', 'user', TRUE)
ON CONFLICT (id) DO NOTHING;

-- ==================== PROJECTS ====================

INSERT INTO projects (id, owner_id, title, description, settings)
VALUES
    ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001',
     'Startup Branding',
     'Complete branding package for fintech startup',
     '{"brand": {"colors": ["#2563EB", "#7C3AED", "#EC4899"], "fonts": ["Inter", "Poppins"], "tone": "professional"}}'
    ),
    ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002',
     'Social Media Campaign',
     'Q1 2025 social media content',
     '{"brand": {"colors": ["#10B981", "#F59E0B"], "fonts": ["Roboto", "Montserrat"], "tone": "friendly"}}'
    ),
    ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001',
     'Website Mockups',
     'Landing page designs for product launch',
     '{"brand": {"colors": ["#1F2937", "#F3F4F6", "#EF4444"], "fonts": ["Open Sans"], "tone": "bold"}}'
    )
ON CONFLICT (id) DO NOTHING;

-- ==================== COLLABORATORS ====================

INSERT INTO collaborators (project_id, user_id, role, invited_by)
VALUES
    -- Bob is editor on Alice's project
    ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'editor', '10000000-0000-0000-0000-000000000001'),
    -- Charlie is viewer on Alice's project
    ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000003', 'viewer', '10000000-0000-0000-0000-000000000001')
ON CONFLICT (project_id, user_id) DO NOTHING;

-- ==================== TOKENS ====================

-- Give test users more tokens
UPDATE tokens_balance SET balance = 500 WHERE user_id = '10000000-0000-0000-0000-000000000001';
UPDATE tokens_balance SET balance = 300 WHERE user_id = '10000000-0000-0000-0000-000000000002';
UPDATE tokens_balance SET balance = 200 WHERE user_id = '10000000-0000-0000-0000-000000000003';

-- ==================== TRANSACTIONS ====================

INSERT INTO transactions (id, user_id, amount, type, status, metadata, completed_at)
VALUES
    -- Alice purchased tokens
    ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 500, 'purchase', 'completed',
     '{"package": "pro", "stripePaymentIntent": "pi_test_123"}', NOW()),

    -- Alice used tokens for AI generation
    ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', -150, 'deduction', 'completed',
     '{"jobId": "40000000-0000-0000-0000-000000000001", "tool": "logo-generator"}', NOW()),

    -- Bob purchased tokens
    ('30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002', 300, 'purchase', 'completed',
     '{"package": "starter", "stripePaymentIntent": "pi_test_456"}', NOW())
ON CONFLICT (id) DO NOTHING;

-- ==================== ASSETS ====================

INSERT INTO assets (id, project_id, created_by, url, type, metadata, size)
VALUES
    ('50000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001',
     '10000000-0000-0000-0000-000000000001',
     'https://s3.example.com/pixora-assets/logo-fintech-v1.png',
     'image',
     '{"width": 1024, "height": 1024, "format": "png", "generatedBy": "logo-generator"}',
     524288
    ),
    ('50000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001',
     '10000000-0000-0000-0000-000000000001',
     'https://s3.example.com/pixora-assets/logo-fintech-v2.svg',
     'svg',
     '{"format": "svg", "generatedBy": "logo-generator"}',
     10240
    ),
    ('50000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000002',
     '10000000-0000-0000-0000-000000000002',
     'https://s3.example.com/pixora-assets/social-post-q1.png',
     'image',
     '{"width": 1080, "height": 1080, "format": "png", "generatedBy": "social-post"}',
     768000
    )
ON CONFLICT (id) DO NOTHING;

-- ==================== AI JOBS ====================

INSERT INTO ai_jobs (id, user_id, project_id, tool, prompt, parameters, status, progress, estimated_tokens, transaction_id, result, completed_at)
VALUES
    ('40000000-0000-0000-0000-000000000001',
     '10000000-0000-0000-0000-000000000001',
     '20000000-0000-0000-0000-000000000001',
     'logo-generator',
     'Create a modern logo for a fintech startup',
     '{"style": "modern", "industry": "fintech", "colors": ["#2563EB", "#7C3AED"]}',
     'completed',
     100,
     150,
     '30000000-0000-0000-0000-000000000002',
     '{"assetIds": ["50000000-0000-0000-0000-000000000001", "50000000-0000-0000-0000-000000000002"]}',
     NOW()
    ),
    ('40000000-0000-0000-0000-000000000002',
     '10000000-0000-0000-0000-000000000002',
     '20000000-0000-0000-0000-000000000002',
     'social-post',
     'Create an Instagram post for our product launch',
     '{"platform": "instagram", "tone": "friendly"}',
     'processing',
     60,
     200,
     NULL,
     NULL,
     NULL
    )
ON CONFLICT (id) DO NOTHING;

-- ==================== SUBSCRIPTIONS ====================

INSERT INTO subscriptions (id, user_id, stripe_subscription_id, stripe_customer_id, plan_id, status, current_period_start, current_period_end, tokens_allowance)
VALUES
    ('60000000-0000-0000-0000-000000000001',
     '10000000-0000-0000-0000-000000000001',
     'sub_test_123',
     'cus_test_alice',
     'pro',
     'active',
     NOW(),
     NOW() + INTERVAL '30 days',
     1000
    )
ON CONFLICT (id) DO NOTHING;

COMMIT;

-- ==================== VERIFICATION QUERIES ====================

SELECT '=== USERS ===' AS info;
SELECT id, email, first_name, last_name, role FROM users ORDER BY created_at;

SELECT '=== PROJECTS ===' AS info;
SELECT id, title, owner_id FROM projects ORDER BY created_at;

SELECT '=== TOKEN BALANCES ===' AS info;
SELECT u.email, tb.balance
FROM tokens_balance tb
JOIN users u ON tb.user_id = u.id
ORDER BY tb.balance DESC;

SELECT '=== TRANSACTIONS ===' AS info;
SELECT u.email, t.amount, t.type, t.status, t.created_at
FROM transactions t
JOIN users u ON t.user_id = u.id
ORDER BY t.created_at DESC
LIMIT 10;

SELECT '=== ASSETS ===' AS info;
SELECT p.title, a.type, a.url
FROM assets a
JOIN projects p ON a.project_id = p.id
ORDER BY a.created_at DESC
LIMIT 10;
