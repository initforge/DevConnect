-- Migration 003: Add user_post_interactions table (recommendation engine)
-- Apply: psql -d devconnect -f backend/migrations/003_add_user_post_interactions.sql

CREATE TABLE IF NOT EXISTS user_post_interactions (
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    interaction_type TEXT NOT NULL CHECK (interaction_type IN ('view', 'like', 'comment', 'bookmark')),
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, post_id, interaction_type)
);
CREATE INDEX IF NOT EXISTS idx_interactions_user ON user_post_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_interactions_post ON user_post_interactions(post_id);
CREATE INDEX IF NOT EXISTS idx_interactions_type ON user_post_interactions(interaction_type);
