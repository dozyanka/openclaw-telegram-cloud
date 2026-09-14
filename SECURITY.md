# Security Policy

## Scope

This repository is a deliberately restricted public-demo Telegram bot. It is not designed to expose OpenClaw administration, host files, shell access, or a personal assistant workspace to Telegram users.

## Security controls

The runtime applies the following controls on every container start:

- `tools.deny = ["*"]`;
- no host directories mounted into the container;
- Telegram groups disabled;
- administrative/native/chat commands disabled;
- Telegram configuration writes disabled;
- private-network access from the Telegram channel disabled;
- persistent memory plugins disabled;
- per-sender Telegram sessions;
- OpenClaw state recreated under `/tmp`;
- Gateway bound to loopback;
- credentials supplied through environment variables / SecretRefs rather than committed files.

## Never commit

Do not commit:

- Telegram bot tokens;
- Gemini/API keys;
- Gateway tokens or passwords;
- `.env`;
- `.openclaw` state;
- chat/session databases;
- `USER.md`, `MEMORY.md`, personal memory folders or personal documents;
- local machine paths or host-specific configuration.

## Public-DM tradeoff

For the technical demo, Telegram DMs use:

```text
dmPolicy = open
allowFrom = ["*"]
```

That means anyone who discovers the bot username can send messages and consume model quota while the deployment is online. It does **not** intentionally grant those users OpenClaw tools or host access.

For a long-lived private deployment, change the Telegram policy to pairing or an explicit allowlist.

## Reporting a vulnerability

For non-sensitive documentation/configuration mistakes, open a GitHub issue.

For a vulnerability that could expose credentials, host data, or remote execution, do not publish exploit details in a public issue. Use GitHub Private Vulnerability Reporting if it is enabled for the repository, or contact the repository owner privately through an available GitHub contact method.

## Supported version

Security fixes are applied to the current `main` branch and the latest tagged release only.
