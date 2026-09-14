# Security notes

## Never commit

- Telegram bot tokens
- Gemini/API keys
- Gateway tokens/passwords
- `.env`
- OpenClaw state (`.openclaw`)
- Chat/session databases
- `USER.md`, `MEMORY.md`, or personal memory folders

## Public-bot tradeoff

The evaluator must be able to message the bot without manual approval, so direct messages are public. The compensating controls are:

- no OpenClaw tools;
- no shell/exec surface;
- no admin/config/plugin/debug/restart chat commands;
- no Telegram groups;
- no host mounts;
- no personal workspace;
- isolated per-sender sessions;
- ephemeral OpenClaw state;
- no public Gateway port.

After evaluation, disable the deployment or change Telegram access to `pairing` / `allowlist`.
