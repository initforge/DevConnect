-- DevConnect Database Initialization Script
-- PostgreSQL 16+

-- Enable UUID extension if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    avatar_url TEXT,
    bio TEXT,
    skills TEXT NOT NULL DEFAULT '[]',
    follower_count INTEGER NOT NULL DEFAULT 0,
    following_count INTEGER NOT NULL DEFAULT 0,
    post_count INTEGER NOT NULL DEFAULT 0,
    reputation INTEGER NOT NULL DEFAULT 0,
    is_online INTEGER NOT NULL DEFAULT 0,
    is_mentor INTEGER NOT NULL DEFAULT 0,
    is_followed_by_me INTEGER NOT NULL DEFAULT 0,
    password_hash TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Posts table
CREATE TABLE IF NOT EXISTS posts (
    id TEXT PRIMARY KEY,
    author_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'article',
    tags TEXT NOT NULL DEFAULT '[]',
    image_url TEXT,
    view_count INTEGER NOT NULL DEFAULT 0,
    like_count INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    bookmark_count INTEGER NOT NULL DEFAULT 0,
    is_liked_by_me INTEGER NOT NULL DEFAULT 0,
    is_bookmarked_by_me INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Comments table
CREATE TABLE IF NOT EXISTS comments (
    id TEXT PRIMARY KEY,
    post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    author_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    depth INTEGER NOT NULL DEFAULT 0,
    upvotes INTEGER NOT NULL DEFAULT 0,
    reply_count INTEGER NOT NULL DEFAULT 0,
    is_best INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    from_user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    is_read INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY,
    owner_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    tech_stack TEXT NOT NULL DEFAULT '[]',
    status TEXT NOT NULL DEFAULT 'LOOKING_FOR_MEMBERS',
    member_count INTEGER NOT NULL DEFAULT 1,
    max_members INTEGER NOT NULL DEFAULT 5,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Jobs table
CREATE TABLE IF NOT EXISTS jobs (
    id TEXT PRIMARY KEY,
    company TEXT NOT NULL,
    title TEXT NOT NULL,
    location TEXT NOT NULL,
    remote INTEGER NOT NULL DEFAULT 0,
    salary_range TEXT NOT NULL,
    tech_stack TEXT NOT NULL DEFAULT '[]',
    experience TEXT NOT NULL,
    match_percent INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY,
    other_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    last_message TEXT NOT NULL,
    unread_count INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'text',
    code_language TEXT,
    code_source TEXT,
    reactions TEXT NOT NULL DEFAULT '[]',
    is_read INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- User follows table
CREATE TABLE IF NOT EXISTS user_follows (
    id TEXT PRIMARY KEY,
    follower_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(follower_id, following_id)
);

-- Post likes table
CREATE TABLE IF NOT EXISTS post_likes (
    id TEXT PRIMARY KEY,
    post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(post_id, user_id)
);

-- Post bookmarks table
CREATE TABLE IF NOT EXISTS post_bookmarks (
    id TEXT PRIMARY KEY,
    post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(post_id, user_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_posts_author_id ON posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_type ON posts(type);
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_author_id ON comments(author_id);
CREATE INDEX IF NOT EXISTS idx_notifications_from_user_id ON notifications(from_user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_follows_follower ON user_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_user_follows_following ON user_follows(following_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_post ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user ON post_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_post_bookmarks_post ON post_bookmarks(post_id);
CREATE INDEX IF NOT EXISTS idx_post_bookmarks_user ON post_bookmarks(user_id);

-- Seed data
INSERT INTO users (id, username, display_name, email, avatar_url, bio, skills, follower_count, following_count, post_count, reputation, is_online, is_mentor, is_followed_by_me, created_at)
VALUES
    ('u1', 'minhdev', 'Minh Nguyen', 'minh@dev.com', NULL, 'Flutter & backend developer. Yeu clean code.', 'Flutter|Dart|Node.js|SQLite', 1250, 340, 48, 3200, 1, 0, 0, '2025-01-01 00:00:00'),
    ('u2', 'anhtran', 'Anh Tran', 'anh@dev.com', NULL, 'Backend engineer. Dam me distributed systems.', 'Go|Docker|PostgreSQL|Redis', 890, 210, 35, 2800, 1, 1, 0, '2025-02-01 00:00:00'),
    ('u3', 'linhpham', 'Linh Pham', 'linh@dev.com', NULL, 'AI/ML researcher. Python, PyTorch.', 'Python|PyTorch|FastAPI|AI', 2100, 180, 62, 4500, 0, 1, 0, '2024-11-01 00:00:00'),
    ('u4', 'ducle', 'Duc Le', 'duc@dev.com', NULL, 'React & Next.js. UI/UX enthusiast.', 'React|TypeScript|Next.js|Tailwind', 650, 420, 27, 1800, 1, 0, 0, '2025-03-01 00:00:00'),
    ('u5', 'thuhuong', 'Thu Huong', 'thu@dev.com', NULL, 'Full-stack developer. Vue & Spring Boot.', 'Vue|Spring Boot|Java|Kubernetes', 520, 150, 19, 1500, 0, 0, 0, '2025-04-01 00:00:00'),
    ('u6', 'nampham', 'Nam Pham', 'nam@dev.com', NULL, 'Mobile developer. Flutter & React Native.', 'Flutter|React Native|Dart|TypeScript', 780, 290, 31, 2100, 1, 0, 0, '2025-03-15 00:00:00')
-- Password hash for 'password123': $2b$10$jt0Jk7nqZEvNJCvy50bRCuDxDHIcIGa6JaMXluIXcioUG3/L78O8S
ON CONFLICT (id) DO NOTHING;

INSERT INTO posts (id, author_id, title, content, type, tags, view_count, like_count, comment_count, bookmark_count, is_liked_by_me, is_bookmarked_by_me, created_at)
VALUES
    ('p1', 'u1', 'SQLite local-first trong Flutter midterm', 'Dung SQLite giup app demo doc lap, khong phu thuoc server. Repository layer giup sau nay doi sang backend API de hon.', 'article', 'Flutter|SQLite|Repository', 1240, 89, 2, 45, 1, 0, '2026-05-01 10:00:00'),
    ('p2', 'u2', 'Backend API se xu ly logic nao?', 'Backend nen xu ly auth, validation, sync, realtime, notification, analytics va AI/recommendation khi san pham len full scope.', 'discussion', 'Backend|API|Architecture', 890, 67, 1, 32, 0, 1, '2026-05-02 14:30:00'),
    ('p3', 'u3', 'Roadmap AI code review cho DevConnect', 'AI code review se nam o phase sau, khong claim trong midterm. Nen bat dau bang API contract va job queue rieng.', 'project', 'AI|Roadmap|Code Review', 2300, 156, 0, 78, 1, 1, '2026-05-03 09:15:00'),
    ('p4', 'u4', 'Next.js 15 - Nhung thay doi quan trong', 'Next.js 15 mang den nhieu cap nhat ve performance va developer experience. Trong do co App Router improvements.', 'article', 'Next.js|React|TypeScript', 1560, 98, 5, 56, 0, 0, '2026-05-03 16:45:00'),
    ('p5', 'u1', 'Docker Compose cho multi-service app', 'Docker Compose giup define va chay multi-container Docker applications. Rat huu ich khi develop microservice architecture.', 'snippet', 'Docker|Compose|DevOps', 780, 45, 3, 28, 0, 0, '2026-05-04 08:20:00'),
    ('p6', 'u5', 'Vue 3 Composition API tips', 'Mot so tips khi su dung Composition API trong Vue 3 de code tot hon va trach nhung loi thuong gap.', 'til', 'Vue|JavaScript|Tips', 620, 38, 2, 19, 1, 0, '2026-05-04 11:00:00'),
    ('p7', 'u6', 'Flutter 3.29 - Cool new features', 'Flutter 3.29 co nhieu features moi, dac biet la ve performance va hot reload. Can than voi breaking changes.', 'article', 'Flutter|Dart|Mobile', 1890, 112, 8, 67, 1, 1, '2026-05-04 15:30:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO comments (id, post_id, author_id, content, depth, upvotes, reply_count, is_best, created_at)
VALUES
    ('c1', 'p1', 'u2', 'Huong nay hop ly cho midterm, mien la report noi ro backend la phase sau.', 0, 12, 0, 0, '2026-05-01 11:00:00'),
    ('c2', 'p1', 'u4', 'Repository boundary se giup refactor sang API it dau hon.', 0, 5, 0, 0, '2026-05-01 12:30:00'),
    ('c3', 'p2', 'u1', 'Backend prototype co the dung SQLite server-side truoc, sau do doi sang PostgreSQL.', 0, 8, 0, 0, '2026-05-02 15:00:00'),
    ('c4', 'p4', 'u5', 'Next.js 15 breaking changes require migration time. Worth it though.', 0, 15, 0, 1, '2026-05-03 18:00:00'),
    ('c5', 'p7', 'u1', 'Flutter 3.29 impeller renderer improving performance significantly on iOS.', 0, 22, 0, 1, '2026-05-04 16:00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO notifications (id, type, title, body, from_user_id, is_read, created_at)
VALUES
    ('n1', 'COMMENT', 'Binh luan moi', 'Anh Tran binh luan ve bai SQLite local-first', 'u2', 0, '2026-05-04 14:00:00'),
    ('n2', 'LIKE', 'Thich bai viet', 'Minh Nguyen thich bai viet cua ban', 'u1', 0, '2026-05-04 13:30:00'),
    ('n3', 'FOLLOW', 'Theo doi moi', 'Linh Pham bat dau theo doi ban', 'u3', 1, '2026-05-04 10:00:00'),
    ('n4', 'MENTION', 'Duoc nhac den', 'Duc Le nhac den ban trong bai viet', 'u4', 0, '2026-05-04 09:00:00'),
    ('n5', 'BEST_ANSWER', 'Tra loi xuat sac', 'Cau tra loi cua ban duoc chon la Best Answer', 'u1', 1, '2026-05-03 20:00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO projects (id, owner_id, title, description, tech_stack, status, member_count, max_members, created_at)
VALUES
    ('proj1', 'u3', 'AI Code Reviewer', 'Bot review code tu dong bang AI service trong phase sau.', 'Python|FastAPI|React|Docker', 'LOOKING_FOR_MEMBERS', 2, 4, '2026-05-01 00:00:00'),
    ('proj2', 'u1', 'DevConnect Mobile', 'Mang xa hoi cho lap trinh vien, phase midterm dung Flutter + SQLite.', 'Flutter|SQLite|Node.js', 'ACTIVE', 3, 5, '2026-04-20 00:00:00'),
    ('proj3', 'u4', 'E-Commerce Platform', 'Full-stack e-commerce voi Next.js va Spring Boot.', 'Next.js|Spring Boot|PostgreSQL|Docker', 'LOOKING_FOR_MEMBERS', 1, 4, '2026-04-25 00:00:00'),
    ('proj4', 'u5', 'Task Management App', 'Ung dung quan ly cong viec voi Vue 3 va Node.js.', 'Vue|Node.js|MongoDB|Tailwind', 'ACTIVE', 2, 3, '2026-04-28 00:00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO jobs (id, company, title, location, remote, salary_range, tech_stack, experience, match_percent, created_at)
VALUES
    ('j1', 'TechCorp VN', 'Flutter Developer', 'Ho Chi Minh', 1, '$1,200 - $2,000', 'Flutter|Dart|SQLite|Firebase', '2-4 nam', 92, '2026-05-01 00:00:00'),
    ('j2', 'StartupX', 'Backend Engineer', 'Ha Noi', 1, '$1,500 - $2,500', 'Node.js|PostgreSQL|Redis|Docker', '3-5 nam', 78, '2026-05-02 00:00:00'),
    ('j3', 'DataAI Corp', 'Data Engineer', 'Da Nang', 0, '$1,800 - $3,000', 'Python|Spark|Airflow|GCP', '3-5 nam', 85, '2026-05-03 00:00:00'),
    ('j4', 'CloudTech VN', 'DevOps Engineer', 'Ho Chi Minh', 1, '$1,400 - $2,200', 'Kubernetes|Docker|AWS|Terraform', '2-4 nam', 73, '2026-05-04 00:00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO conversations (id, other_user_id, last_message, unread_count, updated_at)
VALUES
    ('conv1', 'u2', 'Backend prototype da san sang de test API.', 1, '2026-05-04 14:00:00'),
    ('conv2', 'u3', 'AI/recommendation de phase sau.', 0, '2026-05-04 12:00:00'),
    ('conv3', 'u4', 'Minh da deploy len staging. Ban kiểm tra giúp phần auth callback nhé.', 2, '2026-05-04 10:30:00'),
    ('conv4', 'u6', 'Flutter 3.29 co nhieu thay doi nho ve rendering.', 0, '2026-05-04 08:00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO messages (id, conversation_id, sender_id, content, type, reactions, is_read, created_at)
VALUES
    ('m1', 'conv1', 'u2', 'Backend prototype da san sang de test API.', 'text', '[]', 1, '2026-05-04 13:55:00'),
    ('m2', 'conv1', 'u1', 'Ok, phase midterm van giu SQLite local trong Flutter.', 'text', '[]', 1, '2026-05-04 14:00:00'),
    ('m3', 'conv2', 'u3', 'AI/recommendation de phase sau nhe.', 'text', '[]', 1, '2026-05-04 12:00:00'),
    ('m4', 'conv3', 'u4', 'Minh da deploy len staging.', 'text', '[]', 1, '2026-05-04 10:25:00'),
    ('m5', 'conv3', 'u4', 'Ban kiểm tra giúp phần auth callback nhé.', 'text', '[]', 0, '2026-05-04 10:30:00'),
    ('m6', 'conv4', 'u6', 'Flutter 3.29 co nhieu thay doi nho ve rendering.', 'text', '[]', 1, '2026-05-04 08:00:00')
ON CONFLICT (id) DO NOTHING;