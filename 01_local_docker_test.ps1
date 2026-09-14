$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host '=== Local Docker test ===' -ForegroundColor Cyan

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw 'Docker is not installed. Install/start Docker Desktop, or skip local test and use GitHub Actions build verification.'
}

docker version *> $null
if ($LASTEXITCODE -ne 0) { throw 'Docker engine is not running. Start Docker Desktop first.' }

if (-not (Test-Path '.env')) {
  Copy-Item '.env.example' '.env'
  Write-Host 'Created .env from .env.example.' -ForegroundColor Yellow
  Write-Host 'Open .env and replace the three placeholder secrets, then run this script again.' -ForegroundColor Yellow
  Write-Host 'DO NOT send those secrets to chat and DO NOT commit .env.' -ForegroundColor Yellow
  exit 2
}

$envText = Get-Content '.env' -Raw
if ($envText -match 'replace_me|replace_with_a_long_random_value') {
  throw '.env still contains placeholders. Fill TELEGRAM_BOT_TOKEN, GEMINI_API_KEY and OPENCLAW_GATEWAY_TOKEN.'
}

Write-Host '[1/2] Building image...'
docker build -t openclaw-telegram-cloud:local .
if ($LASTEXITCODE -ne 0) { throw 'docker build failed' }

Write-Host '[2/2] Starting bot. Keep this window open for the local test. Ctrl+C stops it.'
Write-Host 'Send a Telegram message to the bot after the Gateway becomes ready.' -ForegroundColor Cyan
docker run --rm --name openclaw-telegram-cloud-local --env-file .env openclaw-telegram-cloud:local
