$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host '=== OpenClaw repository verification ===' -ForegroundColor Cyan

$required = @(
  'Dockerfile',
  'start.sh',
  '.env.example',
  '.gitignore',
  'README.md',
  'SECURITY.md',
  'LICENSE',
  'CHANGELOG.md',
  'workspace\SOUL.md',
  'workspace\AGENTS.md',
  'workspace\IDENTITY.md',
  '.github\workflows\build.yml'
)

$missing = @($required | Where-Object { -not (Test-Path $_) })
if ($missing.Count -gt 0) {
  throw "Missing required files: $($missing -join ', ')"
}
Write-Host '[OK] Required files are present.' -ForegroundColor Green

if (Test-Path '.env') {
  Write-Warning '.env exists locally. This is OK for local testing ONLY; it must never be committed.'
} else {
  Write-Host '[OK] No local .env file exists.' -ForegroundColor Green
}

$gitignore = Get-Content '.gitignore' -Raw
if ($gitignore -notmatch '(?m)^\.env$') { throw '.gitignore does not ignore .env' }
Write-Host '[OK] .env is ignored by Git.' -ForegroundColor Green

$files = Get-ChildItem -Recurse -File | Where-Object {
  $_.FullName -notmatch '\\.git\\' -and $_.Name -ne '.env'
}

$patterns = @(
  'C:\\Users\\[^\\\s]+',
  '\b\d{8,12}:AA[A-Za-z0-9_-]{20,}\b',
  '(?m)^TELEGRAM_BOT_TOKEN=(?!replace_me\s*$).+',
  '(?m)^GEMINI_API_KEY=(?!replace_me\s*$).+'
)

$hits = @()
foreach ($f in $files) {
  try { $text = Get-Content $f.FullName -Raw -ErrorAction Stop } catch { continue }
  foreach ($p in $patterns) {
    if ($text -match $p) {
      $hits += "$($f.FullName) -> pattern: $p"
    }
  }
}

if ($hits.Count -gt 0) {
  Write-Host ($hits -join "`n") -ForegroundColor Red
  throw 'Privacy/secret scan found suspicious content. Do not push.'
}
Write-Host '[OK] No known local paths or credential patterns found.' -ForegroundColor Green

$start = Get-Content 'start.sh' -Raw
$hardeningChecks = @{
  'all agent tools denied' = 'openclaw config set tools.deny'
  'wildcard deny policy' = '["*"]'
  'Telegram groups disabled' = 'channels.telegram.groupPolicy disabled'
  'per-sender sessions' = 'session.scope per-sender'
  'Gateway loopback binding' = 'gateway.bind loopback'
  'Telegram config writes disabled' = 'channels.telegram.configWrites false'
  'private-network access disabled' = 'channels.telegram.network.dangerouslyAllowPrivateNetwork false'
}

foreach ($name in $hardeningChecks.Keys) {
  if (-not $start.Contains($hardeningChecks[$name])) {
    throw "Missing hardening control: $name"
  }
}
Write-Host '[OK] Required runtime hardening controls are present.' -ForegroundColor Green

if (Get-Command git -ErrorAction SilentlyContinue) {
  Write-Host "[OK] Git: $(git --version)" -ForegroundColor Green

  if (Test-Path '.git') {
    $trackedEnv = git ls-files --error-unmatch .env 2>$null
    if ($LASTEXITCODE -eq 0 -and $trackedEnv) {
      throw '.env is tracked by Git. Remove it from the index before pushing.'
    }
    Write-Host '[OK] .env is not tracked by Git.' -ForegroundColor Green
  }
} else {
  Write-Warning 'Git is not installed.'
}

if (Get-Command gh -ErrorAction SilentlyContinue) {
  Write-Host "[OK] GitHub CLI: $((gh --version | Select-Object -First 1))" -ForegroundColor Green
} else {
  Write-Warning 'GitHub CLI is not installed.'
}

if (Get-Command docker -ErrorAction SilentlyContinue) {
  try {
    $v = docker version --format '{{.Server.Version}}' 2>$null
    if ($LASTEXITCODE -eq 0 -and $v) {
      Write-Host "[OK] Docker engine: $v" -ForegroundColor Green
    } else {
      Write-Warning 'Docker CLI exists, but Docker engine is not running.'
    }
  } catch {
    Write-Warning 'Docker CLI exists, but Docker engine is not running.'
  }
} else {
  Write-Warning 'Docker is not installed. GitHub Actions can still validate the image build.'
}

Write-Host ''
Write-Host 'Verification complete.' -ForegroundColor Cyan
