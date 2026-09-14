param(
  [switch]$CreateRelease
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git is required' }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI (gh) is required' }
if (-not (Test-Path '.git')) { throw 'Run this script from the cloned/published Git repository.' }

& "$PSScriptRoot\00_verify_repo.ps1"

$repo = (gh repo view --json nameWithOwner --jq '.nameWithOwner').Trim()
if (-not $repo) { throw 'Could not determine GitHub repository.' }

Write-Host "Repository: $repo" -ForegroundColor Cyan

$description = 'Privacy-first OpenClaw Telegram AI bot with Docker, GitHub Actions CI and zero host-tool access.'
$topics = @('openclaw','telegram-bot','ai','docker','privacy','security','gemini','github-actions')

$editArgs = @('repo','edit',$repo,'--description',$description)
foreach ($topic in $topics) {
  $editArgs += @('--add-topic',$topic)
}
& gh @editArgs

Write-Host '[OK] GitHub description and topics updated.' -ForegroundColor Green

git add README.md SECURITY.md LICENSE CHANGELOG.md 00_verify_repo.ps1 04_finalize_github.ps1 .github/workflows/build.yml

$hasStaged = $true
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) { $hasStaged = $false }

if ($hasStaged) {
  git commit -m 'Polish documentation, licensing and security checks'
  git push origin HEAD
  Write-Host '[OK] Changes committed and pushed.' -ForegroundColor Green
} else {
  Write-Host '[OK] No new tracked changes to commit.' -ForegroundColor Green
}

Write-Host ''
Write-Host 'Recent CI runs:' -ForegroundColor Cyan
gh run list --limit 5

if ($CreateRelease) {
  $tag = 'v1.0.0'
  $existingTag = git tag --list $tag
  if (-not $existingTag) {
    git tag -a $tag -m 'v1.0.0 - Initial stable release'
    git push origin $tag
  }

  $existingRelease = gh release view $tag 2>$null
  if ($LASTEXITCODE -ne 0) {
    gh release create $tag `
      --title 'v1.0.0 - Initial stable release' `
      --notes 'Privacy-first OpenClaw Telegram bot with Docker deployment, GitHub Actions CI, environment-backed secrets, stateless runtime, and all agent tools denied.'
    Write-Host '[OK] GitHub Release v1.0.0 created.' -ForegroundColor Green
  } else {
    Write-Host '[OK] GitHub Release v1.0.0 already exists.' -ForegroundColor Green
  }
}

Write-Host ''
Write-Host 'Done.' -ForegroundColor Cyan
