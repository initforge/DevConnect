-- DevConnect Database Initialization Script
-- PostgreSQL 16+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables
DROP TABLE IF EXISTS user_post_interactions CASCADE;
DROP TABLE IF EXISTS mentorship_requests CASCADE;
DROP TABLE IF EXISTS project_members CASCADE;
DROP TABLE IF EXISTS job_applications CASCADE;
DROP TABLE IF EXISTS user_follows CASCADE;
DROP TABLE IF EXISTS post_likes CASCADE;
DROP TABLE IF EXISTS post_bookmarks CASCADE;
DROP TABLE IF EXISTS refresh_tokens CASCADE;
DROP TABLE IF EXISTS fcm_tokens CASCADE;
DROP TABLE IF EXISTS live_code_rooms CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Users table
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    avatar_url TEXT,
    bio TEXT,
    skills TEXT NOT NULL DEFAULT '',
    follower_count INTEGER NOT NULL DEFAULT 0,
    following_count INTEGER NOT NULL DEFAULT 0,
    post_count INTEGER NOT NULL DEFAULT 0,
    reputation INTEGER NOT NULL DEFAULT 0,
    is_online INTEGER NOT NULL DEFAULT 0,
    is_mentor INTEGER NOT NULL DEFAULT 0,
    password_hash TEXT,
    settings TEXT NOT NULL DEFAULT '{}',
    search_vector tsvector,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Posts table
CREATE TABLE posts (
    id TEXT PRIMARY KEY,
    author_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'article',
    tags TEXT NOT NULL DEFAULT '',
    image_url TEXT,
    view_count INTEGER NOT NULL DEFAULT 0,
    like_count INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    bookmark_count INTEGER NOT NULL DEFAULT 0,
    trending_score FLOAT NOT NULL DEFAULT 0,
    search_vector tsvector,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Comments table
CREATE TABLE comments (
    id TEXT PRIMARY KEY,
    post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    parent_id TEXT REFERENCES comments(id) ON DELETE CASCADE,
    author_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    depth INTEGER NOT NULL DEFAULT 0,
    upvotes INTEGER NOT NULL DEFAULT 0,
    reply_count INTEGER NOT NULL DEFAULT 0,
    is_best INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Notifications table
CREATE TABLE notifications (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    from_user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    target_user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    is_read INTEGER NOT NULL DEFAULT 0,
    merged_count INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Projects table
CREATE TABLE projects (
    id TEXT PRIMARY KEY,
    owner_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    tech_stack TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'LOOKING_FOR_MEMBERS',
    member_count INTEGER NOT NULL DEFAULT 1,
    max_members INTEGER NOT NULL DEFAULT 5,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Jobs table
CREATE TABLE jobs (
    id TEXT PRIMARY KEY,
    company TEXT NOT NULL,
    title TEXT NOT NULL,
    location TEXT NOT NULL,
    remote INTEGER NOT NULL DEFAULT 0,
    salary_range TEXT NOT NULL,
    tech_stack TEXT NOT NULL DEFAULT '',
    experience TEXT NOT NULL,
    match_percent INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Conversations table
CREATE TABLE conversations (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    other_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    last_message TEXT NOT NULL DEFAULT '',
    unread_count INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Messages table
CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'text',
    code_language TEXT,
    code_source TEXT,
    reactions TEXT NOT NULL DEFAULT '',
    is_read INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- User follows table
CREATE TABLE user_follows (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(follower_id, following_id)
);

-- Post likes table
CREATE TABLE post_likes (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(post_id, user_id)
);

-- Post bookmarks table
CREATE TABLE post_bookmarks (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(post_id, user_id)
);

-- Refresh tokens table
CREATE TABLE refresh_tokens (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- FCM tokens table
CREATE TABLE fcm_tokens (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Live code rooms table
CREATE TABLE live_code_rooms (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    code TEXT NOT NULL DEFAULT '',
    language TEXT NOT NULL DEFAULT 'javascript',
    revision INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Job applications table
CREATE TABLE job_applications (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    cover_note TEXT NOT NULL DEFAULT '',
    resume_url TEXT,
    status TEXT NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(job_id, user_id)
);

-- Project members table
CREATE TABLE project_members (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'PENDING',
    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, user_id)
);

-- Mentorship requests table
CREATE TABLE mentorship_requests (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
    mentee_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mentor_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')) DEFAULT 'pending',
    note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Mentorship scheduled sessions table
CREATE TABLE mentorship_sessions (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id TEXT NOT NULL REFERENCES mentorship_requests(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMP NOT NULL,
    status TEXT NOT NULL DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Mentorship journal table
CREATE TABLE mentorship_journals (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id TEXT REFERENCES mentorship_requests(id) ON DELETE SET NULL,
    author_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    mentor_feedback TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_mentorship_sessions_request ON mentorship_sessions(request_id);
CREATE INDEX idx_mentorship_sessions_scheduled ON mentorship_sessions(scheduled_at);
CREATE INDEX idx_mentorship_journals_request ON mentorship_journals(request_id);
CREATE INDEX idx_mentorship_journals_author ON mentorship_journals(author_id);

-- User-post interactions table
CREATE TABLE user_post_interactions (
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    interaction_type TEXT NOT NULL CHECK (interaction_type IN ('view', 'like', 'comment', 'bookmark')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, post_id, interaction_type)
);

-- Triggers for FTS
CREATE TRIGGER tsvectorupdate_posts BEFORE INSERT OR UPDATE
ON posts FOR EACH ROW EXECUTE FUNCTION
tsvector_update_trigger(search_vector, 'pg_catalog.english', title, content, tags);

CREATE TRIGGER tsvectorupdate_users BEFORE INSERT OR UPDATE
ON users FOR EACH ROW EXECUTE FUNCTION
tsvector_update_trigger(search_vector, 'pg_catalog.english', username, display_name, bio, skills);

-- Seed data
INSERT INTO users (id, username, display_name, email, avatar_url, bio, skills, follower_count, following_count, post_count, reputation, is_online, is_mentor, password_hash, created_at)
VALUES
    ('u1', 'minhdev', 'Minh Nguyen', 'minh@dev.com', NULL, 'Flutter & backend developer. Yeu clean code.', 'Flutter|Dart|Node.js|SQLite', 1250, 340, 4, 3200, 1, 0, '$2b$10$2f3DChfETnf0a9ntBxiFSOkd7tOjXEDGWnfSsTsDOt/rJ09lt0NU.', '2025-01-01 00:00:00'),
    ('u2', 'anhtran', 'Anh Tran', 'anh@dev.com', NULL, 'Backend engineer. Dam me distributed systems.', 'Go|Docker|PostgreSQL|Redis', 890, 210, 1, 2800, 1, 1, '$2b$10$2f3DChfETnf0a9ntBxiFSOkd7tOjXEDGWnfSsTsDOt/rJ09lt0NU.', '2025-02-01 00:00:00'),
    ('u3', 'linhpham', 'Linh Pham', 'linh@dev.com', NULL, 'AI/ML researcher. Python, PyTorch.', 'Python|PyTorch|FastAPI|AI', 2100, 180, 1, 4500, 0, 1, '$2b$10$2f3DChfETnf0a9ntBxiFSOkd7tOjXEDGWnfSsTsDOt/rJ09lt0NU.', '2024-11-01 00:00:00'),
    ('u4', 'ducle', 'Duc Le', 'duc@dev.com', NULL, 'React & Next.js. UI/UX enthusiast.', 'React|TypeScript|Next.js|Tailwind', 650, 420, 1, 1800, 1, 0, '$2b$10$2f3DChfETnf0a9ntBxiFSOkd7tOjXEDGWnfSsTsDOt/rJ09lt0NU.', '2025-03-01 00:00:00'),
    ('u5', 'thuhuong', 'Thu Huong', 'thu@dev.com', NULL, 'Full-stack developer. Vue & Spring Boot.', 'Vue|Spring Boot|Java|Kubernetes', 520, 150, 1, 1500, 0, 1, '$2b$10$2f3DChfETnf0a9ntBxiFSOkd7tOjXEDGWnfSsTsDOt/rJ09lt0NU.', '2025-04-01 00:00:00'),
    ('u6', 'nampham', 'Nam Pham', 'nam@dev.com', NULL, 'Mobile developer. Flutter & React Native.', 'Flutter|React Native|Dart|TypeScript', 780, 290, 1, 2100, 1, 0, '$2b$10$2f3DChfETnf0a9ntBxiFSOkd7tOjXEDGWnfSsTsDOt/rJ09lt0NU.', '2025-03-15 00:00:00');

INSERT INTO posts (id, author_id, title, content, type, tags, view_count, like_count, comment_count, bookmark_count, trending_score, created_at)
VALUES
    ('p1', 'u1', 'Getting Started with Flutter', 'Flutter is an open-source UI software development kit created by Google.', 'article', 'Flutter|Dart|Mobile', 1500, 120, 10, 45, 85.5, '2025-05-01 10:00:00'),
    ('p2', 'u1', 'SQLite in Flutter', 'How to use SQLite for local storage in your Flutter apps.', 'snippet', 'Flutter|SQLite|Database', 800, 45, 5, 20, 42.0, '2025-05-02 11:00:00'),
    ('p3', 'u2', 'Go Concurrency Patterns', 'Exploring goroutines and channels in Go.', 'article', 'Go|Concurrency|Backend', 1200, 90, 8, 30, 72.0, '2025-05-03 12:00:00'),
    ('p4', 'u3', 'Introduction to PyTorch', 'Building neural networks with PyTorch.', 'article', 'Python|PyTorch|AI', 2000, 180, 15, 60, 98.0, '2025-05-04 13:00:00'),
    ('p5', 'u4', 'React Hooks Explained', 'Understanding useState, useEffect, and more.', 'article', 'React|Frontend|Hooks', 1100, 75, 6, 25, 65.0, '2025-05-05 14:00:00'),
    ('p6', 'u5', 'Vue 3 Composition API', 'Transitioning from Options API to Composition API.', 'article', 'Vue|Frontend|JavaScript', 950, 60, 4, 18, 55.0, '2025-05-06 15:00:00'),
    ('p7', 'u6', 'Flutter vs React Native in 2025', 'A detailed comparison of the two leading mobile frameworks.', 'article', 'Flutter|ReactNative|Mobile', 1800, 150, 20, 50, 92.0, '2025-05-07 16:00:00'),
    ('p8', 'u1', 'Building Scalable Backends with NestJS', 'Best practices for NestJS architecture.', 'article', 'NestJS|Backend|TypeScript', 1300, 110, 12, 35, 78.5, '2025-05-08 17:00:00');

INSERT INTO comments (id, post_id, parent_id, author_id, content, depth, upvotes, reply_count, is_best, created_at)
VALUES
    ('c1', 'p1', NULL, 'u2', 'Great introduction! Very helpful.', 0, 15, 2, 0, '2025-05-01 12:00:00'),
    ('c2', 'p1', 'c1', 'u3', 'I like the way you explained widgets.', 1, 10, 0, 0, '2025-05-01 13:00:00'),
    ('c3', 'p2', NULL, 'u4', 'Can I use this with drift?', 0, 5, 0, 0, '2025-05-02 14:00:00'),
    ('c4', 'p4', NULL, 'u1', 'PyTorch is indeed powerful for research.', 0, 20, 0, 1, '2025-05-04 15:00:00'),
    ('c5', 'p7', NULL, 'u2', 'React Native is still relevant for many teams.', 0, 12, 1, 1, '2025-05-07 18:00:00');

INSERT INTO notifications (id, type, title, body, from_user_id, target_user_id, is_read, created_at)
VALUES
    ('n1', 'COMMENT', 'Binh luan moi', 'Anh Tran binh luan ve bai SQLite local-first', 'u2', 'u1', 0, '2026-05-04 14:00:00'),
    ('n2', 'LIKE', 'Thich bai viet', 'Minh Nguyen thich bai viet cua ban', 'u1', 'u2', 0, '2026-05-04 13:30:00'),
    ('n3', 'FOLLOW', 'Theo doi moi', 'Linh Pham bat dau theo doi ban', 'u3', 'u1', 1, '2026-05-04 10:00:00'),
    ('n4', 'MENTION', 'Duoc nhac den', 'Duc Le nhac den ban trong bai viet', 'u4', 'u1', 0, '2026-05-04 09:00:00'),
    ('n5', 'BEST_ANSWER', 'Tra loi xuat sac', 'Cau tra loi cua ban duoc chon la Best Answer', 'u1', 'u4', 1, '2026-05-03 20:00:00');

INSERT INTO projects (id, owner_id, title, description, tech_stack, status, member_count, max_members, created_at)
VALUES
    ('proj1', 'u3', 'AI Code Reviewer', 'Bot review code tu dong bang AI service trong phase sau.', 'Python|FastAPI|React|Docker', 'LOOKING_FOR_MEMBERS', 2, 4, '2026-05-01 00:00:00'),
    ('proj2', 'u1', 'DevConnect Mobile', 'Mang xa hoi cho lap trinh vien, phase midterm dung Flutter + SQLite.', 'Flutter|SQLite|Node.js', 'ACTIVE', 3, 5, '2026-04-20 00:00:00'),
    ('proj3', 'u4', 'E-Commerce Platform', 'Full-stack e-commerce voi Next.js va Spring Boot.', 'Next.js|Spring Boot|PostgreSQL|Docker', 'LOOKING_FOR_MEMBERS', 1, 4, '2026-04-25 00:00:00'),
    ('proj4', 'u5', 'Task Management App', 'Ung dung quan ly cong viec voi Vue 3 va Node.js.', 'Vue|Node.js|MongoDB|Tailwind', 'ACTIVE', 2, 3, '2026-04-28 00:00:00');

INSERT INTO jobs (id, company, title, location, remote, salary_range, tech_stack, experience, match_percent, created_at)
VALUES
    ('j1', 'TechCorp VN', 'Flutter Developer', 'Ho Chi Minh', 1, '$1,200 - $2,000', 'Flutter|Dart|SQLite|Firebase', '2-4 nam', 92, '2026-05-01 00:00:00'),
    ('j2', 'StartupX', 'Backend Engineer', 'Ha Noi', 1, '$1,500 - $2,500', 'Node.js|PostgreSQL|Redis|Docker', '3-5 nam', 78, '2026-05-02 00:00:00'),
    ('j3', 'DataAI Corp', 'Data Engineer', 'Da Nang', 0, '$1,800 - $3,000', 'Python|Spark|Airflow|GCP', '3-5 nam', 85, '2026-05-03 00:00:00'),
    ('j4', 'CloudTech VN', 'DevOps Engineer', 'Ho Chi Minh', 1, '$1,400 - $2,200', 'Kubernetes|Docker|AWS|Terraform', '2-4 nam', 73, '2026-05-04 00:00:00');

INSERT INTO conversations (id, user_id, other_user_id, last_message, unread_count, updated_at)
VALUES
    ('conv1', 'u1', 'u2', 'Backend prototype da san sang de test API.', 1, '2026-05-04 14:00:00'),
    ('conv2', 'u1', 'u3', 'AI/recommendation de phase sau.', 0, '2026-05-04 12:00:00'),
    ('conv3', 'u1', 'u4', 'Minh da deploy len staging. Ban kiểm tra giúp phần auth callback nhé.', 2, '2026-05-04 10:30:00'),
    ('conv4', 'u1', 'u6', 'Flutter 3.29 co nhieu thay doi nho ve rendering.', 0, '2026-05-04 08:00:00');

INSERT INTO messages (id, conversation_id, sender_id, content, type, reactions, is_read, created_at)
VALUES
    ('m1', 'conv1', 'u2', 'Backend prototype da san sang de test API.', 'text', '[]', 1, '2026-05-04 13:55:00'),
    ('m2', 'conv1', 'u1', 'Ok, phase midterm van giu SQLite local trong Flutter.', 'text', '[]', 1, '2026-05-04 14:00:00'),
    ('m3', 'conv2', 'u3', 'AI/recommendation de phase sau nhe.', 'text', '[]', 1, '2026-05-04 12:00:00'),
    ('m4', 'conv3', 'u4', 'Minh da deploy len staging.', 'text', '[]', 1, '2026-05-04 10:25:00'),
    ('m5', 'conv3', 'u4', 'Ban kiểm tra giúp phần auth callback nhé.', 'text', '[]', 0, '2026-05-04 10:30:00'),
    ('m6', 'conv4', 'u6', 'Flutter 3.29 co nhieu thay doi nho ve rendering.', 'text', '[]', 1, '2026-05-04 08:00:00');
