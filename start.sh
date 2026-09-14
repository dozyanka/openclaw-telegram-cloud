#!/bin/sh
set -eu
umask 077

require_env() {
  var_name="$1"
  eval "var_value=\${$var_name:-}"
  if [ -z "$var_value" ]; then
    echo "ERROR: required environment variable $var_name is not set" >&2
    exit 1
  fi
}

require_env TELEGRAM_BOT_TOKEN
require_env GEMINI_API_KEY
require_env OPENCLAW_GATEWAY_TOKEN

export HOME=/home/node
export OPENCLAW_STATE_DIR="${OPENCLAW_STATE_DIR:-/tmp/openclaw}"
export OPENCLAW_CONFIG_DIR="$OPENCLAW_STATE_DIR"
export OPENCLAW_CONFIG_PATH="$OPENCLAW_STATE_DIR/openclaw.json"
export OPENCLAW_WORKSPACE_DIR="$OPENCLAW_STATE_DIR/workspace"
export OPENCLAW_MODEL="${OPENCLAW_MODEL:-google/gemini-3.1-flash-lite}"

# Privacy-first, stateless startup. No previous chats, local machine paths,
# user profile, or credentials are baked into the image or repository.
rm -rf "$OPENCLAW_STATE_DIR"
mkdir -p "$OPENCLAW_WORKSPACE_DIR"
cp -R /home/node/cloud-workspace/. "$OPENCLAW_WORKSPACE_DIR/"
chmod -R go-rwx "$OPENCLAW_STATE_DIR" || true

# Credentials are kept as environment-backed SecretRefs, not plaintext config.
openclaw onboard \
  --non-interactive \
  --accept-risk \
  --skip-health \
  --mode local \
  --auth-choice gemini-api-key \
  --secret-input-mode ref \
  --gateway-auth token \
  --gateway-token-ref-env OPENCLAW_GATEWAY_TOKEN \
  --skip-channels \
  --skip-bootstrap \
  --skip-skills \
  --no-install-daemon

# Telegram token stays in TELEGRAM_BOT_TOKEN and is referenced from the environment.
openclaw channels add --channel telegram --use-env

# Use the repository-supplied anonymous workspace.
openclaw config set agents.defaults.workspace "$OPENCLAW_WORKSPACE_DIR"
openclaw config set agents.defaults.skills '[]' --strict-json
openclaw models set "$OPENCLAW_MODEL"

# The public bot is deliberately tool-less. It can generate text, but cannot
# execute commands, browse the host, read files, call tools, or inspect runtime state.
openclaw config set tools.deny '["*"]' --strict-json

# Do not expose administrative/chat command surfaces to public Telegram users.
openclaw config set commands.native false --strict-json
openclaw config set commands.nativeSkills false --strict-json
openclaw config set commands.text false --strict-json
openclaw config set commands.bash false --strict-json
openclaw config set commands.config false --strict-json
openclaw config set commands.mcp false --strict-json
openclaw config set commands.plugins false --strict-json
openclaw config set commands.debug false --strict-json
openclaw config set commands.restart false --strict-json

# Public DMs are needed so an evaluator can test the bot without coordination.
# Groups are disabled and every sender gets an isolated session.
openclaw config set channels.telegram.dmPolicy open
openclaw config set channels.telegram.allowFrom '["*"]' --strict-json
openclaw config set channels.telegram.groupPolicy disabled
openclaw config set channels.telegram.configWrites false --strict-json
openclaw config set channels.telegram.linkPreview false --strict-json
openclaw config set channels.telegram.network.dangerouslyAllowPrivateNetwork false --strict-json
openclaw config set channels.telegram.mediaMaxMb 1 --strict-json
openclaw config set session.scope per-sender

# Disable persistent/user-memory plugins for the public test bot.
openclaw config set plugins.entries.memory-core.enabled false --strict-json
openclaw config set plugins.entries.active-memory.enabled false --strict-json

# The Gateway is not meant to be publicly reachable. Telegram uses outbound polling.
openclaw config set gateway.mode local
openclaw config set gateway.bind loopback

openclaw config validate
openclaw secrets audit --check || {
  echo "ERROR: OpenClaw secret audit failed" >&2
  exit 1
}

exec openclaw gateway run --bind loopback
