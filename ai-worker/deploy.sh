#!/usr/bin/env bash
# Deploy DevConnect AI Worker to Cloudflare Workers
# Usage: ./deploy.sh [--env production]

set -euo pipefail

cd "$(dirname "$0")"

ENV_FLAG="${1:---env production}"
ENV_NAME="${ENV_FLAG#--env }"

echo "==> Validating wrangler.toml..."
if [ ! -f wrangler.toml ]; then
  echo "ERROR: wrangler.toml not found"
  exit 1
fi

echo "==> Checking required env vars..."
if [ -z "${AI_WORKER_SECRET:-}" ]; then
  echo "WARN: AI_WORKER_SECRET not set — secrets must be configured via 'wrangler secret put'"
fi

echo "==> Running tests..."
npm test

echo "==> Running syntax check..."
npm run check

echo "==> Deploying worker ${ENV_FLAG}..."
npx wrangler deploy ${ENV_FLAG}

echo "==> Done. Verify at:"
echo "    https://devconnect-ai-worker-${ENV_NAME}.workers.dev"
