# syntax=docker/dockerfile:1
FROM instrumentisto/flutter:latest

# Chỉ cài đặt Chromium để chạy test, không copy code vào đây
# Việc copy code sẽ do Docker Compose đảm nhận qua Volumes
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Container này đóng vai trò là một "Runtime Environment" tinh khiết
CMD ["sleep", "infinity"]
