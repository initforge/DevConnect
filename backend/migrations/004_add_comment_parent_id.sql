-- Migration 004: Add parent_id column to comments table (threaded replies)
-- Apply: psql -d devconnect -f backend/migrations/004_add_comment_parent_id.sql

ALTER TABLE comments ADD COLUMN IF NOT EXISTS parent_id TEXT;
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON comments(parent_id);
