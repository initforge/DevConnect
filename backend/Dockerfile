FROM node:22-alpine

LABEL maintainer="DevConnect Team"

WORKDIR /app

RUN apk add --no-cache dumb-init wget

# Create non-root user first
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

COPY package*.json ./
RUN npm install --omit=dev

COPY . .

RUN mkdir -p /app/data && chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["dumb-init", "--"]

CMD ["node", "src/server.js"]