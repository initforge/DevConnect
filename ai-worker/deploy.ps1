# Deploy DevConnect AI Worker to Cloudflare Workers
# Usage: .\deploy.ps1 [-Env production]
param(
    [string]$Env = "production"
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "==> Validating wrangler.toml..."
if (-not (Test-Path "wrangler.toml")) {
    Write-Host "ERROR: wrangler.toml not found" -ForegroundColor Red
    exit 1
}

Write-Host "==> Checking required env vars..."
if ([string]::IsNullOrEmpty($env:AI_WORKER_SECRET)) {
    Write-Host "WARN: AI_WORKER_SECRET not set — secrets must be configured via 'wrangler secret put'" -ForegroundColor Yellow
}

Write-Host "==> Running tests..."
npm test

Write-Host "==> Running syntax check..."
npm run check

Write-Host "==> Deploying worker (--env $Env)..."
npx wrangler deploy --env $Env

Write-Host "==> Done. Verify at:"
Write-Host "    https://devconnect-ai-worker-$Env.workers.dev"
