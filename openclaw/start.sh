#!/usr/bin/env bash
# Iowa AI Sovereignty Stack — OpenClaw launcher (free, CPU-only backend)
#
#   ./start.sh
#
# Brings up the OpenClaw gateway wired to the local Ollama in ../stack. No GPU,
# no paid API key. First run generates a gateway token and seeds openclaw.json.

set -euo pipefail
cd "$(dirname "$0")"

VOL="iowa-openclaw_openclaw_data"
SEED_IMAGE="${SEED_IMAGE:-alpine}"

command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required: https://docs.docker.com/get-docker/"; exit 1; }

# 1) Free CPU backend: make sure the local Ollama is running.
if [ -d ../stack ]; then
  echo "🌽 Ensuring local Ollama (../stack) is running..."
  ( cd ../stack && docker compose up -d ollama >/dev/null 2>&1 ) || \
    echo "   (couldn't auto-start Ollama — start it yourself: cd ../stack && docker compose up -d ollama)"
fi

# 2) .env + a generated gateway token.
[ -f .env ] || cp .env.example .env
if ! grep -qE '^OPENCLAW_GATEWAY_TOKEN=.+' .env; then
  TOKEN="$(openssl rand -hex 32 2>/dev/null || head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  if grep -q '^OPENCLAW_GATEWAY_TOKEN=' .env; then
    sed -i.bak "s|^OPENCLAW_GATEWAY_TOKEN=.*|OPENCLAW_GATEWAY_TOKEN=${TOKEN}|" .env && rm -f .env.bak
  else
    echo "OPENCLAW_GATEWAY_TOKEN=${TOKEN}" >> .env
  fi
  echo "🔑 Generated a gateway token (stored in ./.env)."
fi

# 3) Seed openclaw.json into the config volume on first run only (owned by the
#    container's node user, uid 1000).
docker volume create "$VOL" >/dev/null
if ! docker run --rm -v "$VOL":/data "$SEED_IMAGE" test -f /data/openclaw.json 2>/dev/null; then
  echo "📝 Seeding openclaw.json (local Ollama backend)..."
  docker run --rm -v "$VOL":/data -v "$PWD":/src:ro "$SEED_IMAGE" sh -c \
    'mkdir -p /data/workspace && cp /src/openclaw.json /data/openclaw.json && chown -R 1000:1000 /data'
fi

# 4) Start the gateway.
docker compose up -d openclaw-gateway

PORT="$(grep -E '^OPENCLAW_GATEWAY_PORT=' .env | cut -d= -f2)"; PORT="${PORT:-18789}"
echo ""
echo "✅ OpenClaw gateway starting."
echo "   • Control UI:  http://localhost:${PORT}  (token is in ./.env)"
echo "   • Backend:     local Ollama 'qwen2.5:3b' on CPU — \$0, no GPU, no API key"
echo "   • CLI:         docker compose run --rm openclaw-cli models list"
echo "   • Stop:        docker compose down"
