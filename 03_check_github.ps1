$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI is not installed.' }
if (-not (Test-Path '.git')) { throw 'This folder is not a Git repository yet.' }

Write-Host '=== GitHub repository ===' -ForegroundColor Cyan
gh repo view --json nameWithOwner,url,visibility,defaultBranchRef --jq '"Repo: \(.nameWithOwner)\nURL: \(.url)\nVisibility: \(.visibility)\nDefault branch: \(.defaultBranchRef.name)"'
Write-Host ''
Write-Host '=== Recent GitHub Actions runs ===' -ForegroundColor Cyan
gh run list --limit 5
Write-Host ''
Write-Host 'To watch the newest run live:' -ForegroundColor Cyan
Write-Host '  gh run watch'
