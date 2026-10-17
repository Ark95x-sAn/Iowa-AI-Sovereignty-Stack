# 🦅 OpenClaw Gateway (free, no-GPU)

[OpenClaw](https://github.com/openclaw/openclaw) is a self-hosted AI **gateway** —
it connects chat apps and channels to an LLM backend you control. This setup runs
it against the **local Ollama** from [`../stack`](../stack/README.md) on your
**CPU**: **$0, no GPU, no paid API key, data stays on your machine.**

> "I don't have money for Ollama" — good news: **Ollama is free.** The only thing
> that costs money is a GPU, and everything here runs on a plain CPU (just
> slower). That's the way around.

---

## Quick start

Requires [Docker](https://docs.docker.com/get-docker/). The local model stack
(`../stack`) provides the free CPU backend.

```bash
# 1) One-time: get a model into the free local backend (if you haven't already)
cd ../stack && ./start.sh        # or: docker compose exec ollama ollama pull qwen2.5:3b

# 2) Start OpenClaw
cd ../openclaw && ./start.sh
```

Then open the control UI at **http://localhost:18789** (the gateway token is
written to `openclaw/.env`).

Check the backend is wired up:

```bash
docker compose run --rm openclaw-cli models list
```

---

## How the free CPU backend is wired

`openclaw.json` points OpenClaw at Ollama's **native API** (no `/v1`):

```json5
models.providers.ollama = {
  apiKey: "ollama-local",
  baseUrl: "http://host.docker.internal:11434",  // the Ollama in ../stack
  api: "ollama",
  models: [ { id: "qwen2.5:3b" } ]
}
agents.defaults.model.primary = "ollama/qwen2.5:3b"
```

Change the model by pulling another one into Ollama (`docker compose exec ollama
ollama pull <model>` in `../stack`) and editing `openclaw.json`.

---

## Reality check on CPU

- **It's slow.** A 3B model on CPU answers in tens of seconds, not instantly.
- **Small models are shaky at tool-calling.** OpenClaw is an agent gateway; tiny
  models sometimes emit malformed tool calls. For plain chat it's fine; for heavy
  agent/tool workflows you'll want a bigger model or a GPU. OpenClaw auto-enables
  [Tool Search](https://github.com/openclaw/openclaw/blob/main/docs/tools/tool-search.md)
  for local Ollama models to help.
- A GPU (or the `deploy:` GPU block in `../stack/docker-compose.yml`) makes it
  near-instant.

---

## Faster alternatives (still cheap)

If CPU is too slow, edit `openclaw.json` / `.env`:

1. **Free hosted API** — e.g. [Groq](https://console.groq.com) free tier. Add an
   OpenAI-compatible provider pointing at the vendor's base URL and put the key in
   `.env`. Fast, no GPU, but you sign up and your prompts leave your machine.
2. **Claude via your existing Claude web session** — OpenClaw accepts a Claude
   session key (`CLAUDE_AI_SESSION_KEY` in `.env`) instead of a paid API key.
   Fast and uses your current Claude access, but it's a gray-area/fragile setup
   that can break when the session rotates.

Keep `models.mode: "merge"` so you can list several backends and fall back
between them.

---

## Running on your Windows desktop

1. Install **Docker Desktop for Windows**.
2. In PowerShell from the repo:
   ```powershell
   cd stack ; docker compose up -d ; docker compose exec ollama ollama pull qwen2.5:3b
   cd ..\openclaw ; docker compose up -d
   ```
   (`start.sh` is bash — run it from WSL/Git Bash, or use the commands above and
   set a token via `OPENCLAW_GATEWAY_TOKEN` in `.env`.)
3. Open http://localhost:18789.

**Want it running 24/7 (even with your PC off)?** See **[DEPLOY.md](DEPLOY.md)** —
Windows steps plus free/cheap always-on hosting (Oracle Cloud free tier, a small
VPS, or a home box), with how to secure the gateway.

---

## Notes

- Image: the project's official Docker Hub mirror `openclaw/openclaw:latest`
  (primary registry is `ghcr.io/openclaw/openclaw`). Override via `OPENCLAW_IMAGE`.
- Ports: `18789` (gateway + UI), `18790` (bridge).
- State/config live in the `openclaw_data` Docker volume.
- Keep `OPENCLAW_GATEWAY_TOKEN` private — it controls the gateway.

Built with 🌽 in Iowa.
