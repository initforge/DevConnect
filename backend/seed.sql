-- DevConnect Seed Script (PostgreSQL)
-- Run with: npm run seed
-- Or directly: psql $DATABASE_URL -f src/seed.sql
--
-- Options:
--   DATABASE_URL='postgresql://user:pass@host:5432/db' npm run seed

-- Minimal seed data for testing - only 3 users
-- Full data should be inserted via app or admin panel

INSERT INTO users (id, username, display_name, email, avatar_url, bio, skills, follower_count, following_count, post_count, reputation, is_online, is_mentor, is_followed_by_me, created_at)
VALUES
    ('u1', 'minhdev', 'Minh Nguyễn', 'minh@dev.com', NULL, 'Flutter & backend developer. Yêu clean code.', '["Flutter","Dart","NestJS","PostgreSQL"]'::jsonb, 1250, 340, 48, 3200, 1, 0, 0, '2025-01-01 00:00:00'),
    ('u2', 'anhtran', 'Anh Trần', 'anh@dev.com', NULL, 'Backend engineer. Đam mê distributed systems.', '["Go","Docker","PostgreSQL","Redis"]'::jsonb, 890, 210, 35, 2800, 1, 1, 0, '2025-02-01 00:00:00'),
    ('u3', 'linhpham', 'Linh Phạm', 'linh@dev.com', NULL, 'AI/ML researcher. Python, PyTorch.', '["Python","PyTorch","FastAPI","AI"]'::jsonb, 2100, 180, 62, 4500, 0, 1, 0, '2024-11-01 00:00:00')
ON CONFLICT (id) DO NOTHING;

-- Add a follow relationship for testing
INSERT INTO user_follows (id, follower_id, following_id, created_at)
VALUES ('f1', 'u1', 'u2', CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

-- Verify seed
SELECT 'Seed users:' as info;
SELECT id, username, display_name FROM users;