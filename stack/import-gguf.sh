#!/usr/bin/env bash
# Import a local .gguf model file into the running Ollama container.
#
#   ./import-gguf.sh /path/to/model.gguf my-model:tag
#
# Why this exists: on restricted or air-gapped networks, `ollama pull` can't
# reach the model registry. Bring a .gguf in however your network allows
# (USB stick, an internal mirror, Docker Hub's `ai/` model namespace, etc.)
# and register it locally so the rest of the stack can use it.
#
# The template below is ChatML, which fits most modern instruct models
# (SmolLM2, Qwen2.5, and others). For a model that uses a different prompt
# format, edit the TEMPLATE/stop lines to match it.

set -euo pipefail

GGUF="${1:?Usage: ./import-gguf.sh <file.gguf> <model-name:tag>}"
NAME="${2:?Usage: ./import-gguf.sh <file.gguf> <model-name:tag>}"

if [ ! -f "$GGUF" ]; then
  echo "❌ No such file: $GGUF"
  exit 1
fi

cd "$(dirname "$0")"

echo "🌽 Ensuring Ollama is running..."
docker compose up -d ollama
for _ in $(seq 1 30); do
  if docker compose exec -T ollama ollama list >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "📦 Copying model into the container..."
docker cp "$GGUF" iowa-ollama:/tmp/import.gguf

docker compose exec -T ollama sh -c 'cat > /tmp/import.Modelfile' <<'MF'
FROM /tmp/import.gguf
TEMPLATE """{{ if .System }}<|im_start|>system
{{ .System }}<|im_end|>
{{ end }}{{ if .Prompt }}<|im_start|>user
{{ .Prompt }}<|im_end|>
{{ end }}<|im_start|>assistant
{{ .Response }}<|im_end|>
"""
PARAMETER stop "<|im_end|>"
MF

echo "🛠️  Registering model as '${NAME}'..."
docker compose exec -T ollama ollama create "${NAME}" -f /tmp/import.Modelfile

echo ""
echo "✅ Imported '${NAME}'. Try it:"
echo "   docker compose exec ollama ollama run ${NAME}"
