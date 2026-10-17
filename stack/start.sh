#!/usr/bin/env bash
# Iowa AI Sovereignty Stack — one-command self-hosted AI launcher
#
#   ./start.sh            # start the stack and pull the default model
#   DEFAULT_MODEL=qwen2.5:0.5b ./start.sh   # override the model for this run
#
# Brings up Ollama + Open WebUI with Docker Compose, waits for Ollama to be
# ready, and pulls the default model so chat works immediately.

set -euo pipefail

cd "$(dirname "$0")"

# Load .env if present; otherwise rely on built-in defaults.
if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

DEFAULT_MODEL="${DEFAULT_MODEL:-llama3.2:3b}"
WEBUI_PORT="${WEBUI_PORT:-3000}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"

if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is required. Install it: https://docs.docker.com/get-docker/"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "❌ Docker Compose v2 is required (ships with modern Docker Desktop)."
  exit 1
fi

echo "🌽 Starting the Iowa AI Sovereignty Stack..."
docker compose up -d

echo "⏳ Waiting for Ollama to be ready..."
for _ in $(seq 1 30); do
  if docker compose exec -T ollama ollama list >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "⬇️  Pulling default model: ${DEFAULT_MODEL}"
echo "    (first run only — this can take a few minutes depending on your connection)"
docker compose exec -T ollama ollama pull "${DEFAULT_MODEL}"

echo ""
echo "✅ Done. Your sovereign AI is running locally:"
echo "   • Chat UI:     http://localhost:${WEBUI_PORT}"
echo "   • Ollama API:  http://localhost:${OLLAMA_PORT}"
echo ""
echo "Stop it with:    docker compose down"
echo "Built with 🌽 in Iowa"
