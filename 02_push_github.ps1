param(
  [string]$RepoName = 'openclaw-telegram-cloud',
  [ValidateSet('public','private')][string]$Visibility = 'public'
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host '=== Push to GitHub ===' -ForegroundColor Cyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw 'Git is not installed. Run: winget install --id Git.Git -e ; then reopen PowerShell.'
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  throw 'GitHub CLI is not installed. Run: winget install --id GitHub.cli -e ; then reopen PowerShell.'
}

& "$PSScriptRoot\00_verify_repo.ps1"
if ($LASTEXITCODE -ne 0) { throw 'Repository verification failed.' }

# Never allow local secrets into the commit.
if (Test-Path '.env') {
  $ignored = git check-ignore .env 2>$null
  if (-not $ignored) { throw '.env exists but Git does not ignore it. Refusing to continue.' }
}

# Authenticate GitHub CLI if needed.
gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host 'GitHub authentication is required. A browser/login flow will open now.' -ForegroundColor Yellow
  gh auth login -h github.com -p https -w
  if ($LASTEXITCODE -ne 0) { throw 'GitHub login failed.' }
}

if (-not (Test-Path '.git')) {
  git init
  git branch -M main
}

# Ensure commit identity exists.
$name = git config user.name
$email = git config user.email
if (-not $name -or -not $email) {
  Write-Host 'Git commit identity is not configured.' -ForegroundColor Yellow
  Write-Host 'Run these once with YOUR GitHub display name/email, then rerun this script:'
  Write-Host '  git config --global user.name "Your Name"'
  Write-Host '  git config --global user.email "your-github-email@example.com"'
  exit 3
}

git add --all
$staged = git diff --cached --name-only
if ($staged -match '(^|/)\.env$') { throw '.env is staged. Refusing to push secrets.' }

if (-not (git rev-parse --verify HEAD 2>$null)) {
  git commit -m 'Initial privacy-first OpenClaw Telegram cloud bot'
} else {
  $changes = git status --porcelain
  if ($changes) {
    git commit -m 'Update OpenClaw Telegram cloud bot'
  } else {
    Write-Host '[OK] No new local changes to commit.' -ForegroundColor Green
  }
}

$origin = git remote get-url origin 2>$null
if (-not $origin) {
  gh repo create $RepoName --$Visibility --source . --remote origin --push
  if ($LASTEXITCODE -ne 0) { throw 'GitHub repository creation/push failed.' }
} else {
  git push -u origin main
  if ($LASTEXITCODE -ne 0) { throw 'git push failed.' }
}

Write-Host ''
Write-Host '[OK] Repository pushed.' -ForegroundColor Green
gh repo view --json nameWithOwner,url,visibility --jq '"Repo: \(.nameWithOwner)\nURL: \(.url)\nVisibility: \(.visibility)"'
Write-Host ''
Write-Host 'GitHub Actions will run the Docker build automatically. Check with:' -ForegroundColor Cyan
Write-Host '  gh run list --limit 5'
