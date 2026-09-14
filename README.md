# OpenClaw Telegram Cloud Bot

Privacy-first, tool-less OpenClaw Telegram bot intended for a public technical-test demo.

## What this repository contains

- Official OpenClaw `2026.9.4` container image.
- Telegram channel configured from an environment secret.
- Google Gemini provider configured from an environment secret.
- No personal `USER.md`, `MEMORY.md`, chat dumps, host paths, usernames, IP addresses, or credentials.
- All OpenClaw agent tools denied (`tools.deny = ["*"]`).
- Telegram groups disabled.
- Public DM access enabled so an evaluator can test the bot without pairing.
- Per-sender sessions so unrelated Telegram users do not share a conversation session.
- Native/admin/chat commands disabled.
- OpenClaw state stored under `/tmp` and recreated on every container start.

## Important: GitHub does not run the bot

GitHub stores the source code. To keep the Telegram bot online while your PC is off, deploy this repository to an always-on Docker host (for example a Docker worker/service on a cloud platform or a VPS).

The host only needs to run the container. The OpenClaw Gateway is bound to loopback because Telegram uses outbound polling; do not publish port 18789 to the Internet.

## Required secrets

Configure these as secrets/environment variables in the hosting platform, not in GitHub:

- `TELEGRAM_BOT_TOKEN` — token from BotFather.
- `GEMINI_API_KEY` — Google AI Studio API key.
- `OPENCLAW_GATEWAY_TOKEN` — a long random value used for Gateway authentication.

Optional:

- `OPENCLAW_MODEL` — defaults to `google/gemini-3.1-flash-lite`.

Generate a Gateway token locally, for example:

```bash
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

## Local Docker test

Create a local `.env` from `.env.example`, put test secrets into it, then run:

```bash
docker build -t openclaw-telegram-cloud .
docker run --rm --env-file .env openclaw-telegram-cloud
```

Do not push `.env`; it is ignored by Git.

## Cloud deployment

1. Push this repository to GitHub.
2. Create a Docker worker/service from the GitHub repository on your hosting provider.
3. Add the three required environment variables in the provider's secret settings.
4. Do not expose a public HTTP port for OpenClaw.
5. Start the service and message the Telegram bot.

## Security model

This is intentionally not a personal assistant. It has no mounted host directories and no personal workspace. Every OpenClaw tool is denied, administrative Telegram commands are disabled, Telegram groups are disabled, private-network access from the Telegram channel is disabled, and secrets are environment-backed rather than committed to the repository.

The bot is public in DMs (`dmPolicy=open`, `allowFrom=["*"]`) so a reviewer can test it without contacting the operator. This means anyone who discovers the bot username can consume model quota while the deployment is online. For a long-lived private bot, switch to an allowlist or pairing after the test.

## Windows / PowerShell quick start

After extracting the archive:

```powershell
cd "C:\path\to\OpenClaw_Telegram_Cloud_v2"
Set-ExecutionPolicy -Scope Process Bypass
.\00_verify_repo.ps1
```

Optional local Docker test:

```powershell
.\01_local_docker_test.ps1
```

Push to a new public GitHub repository:

```powershell
.\02_push_github.ps1 -RepoName openclaw-telegram-cloud -Visibility public
```

Verify repository and CI build:

```powershell
.\03_check_github.ps1
```
