# 🔒 Self-Hosted Sovereign AI Core (Docker)

This is the **actually sovereign** part of the stack: a local AI assistant that
runs entirely on your own machine. No subscriptions, no API keys, no data
leaving your network.

| Component | Role | License |
|-----------|------|---------|
| [Ollama](https://ollama.com) | Runs open LLMs locally (Llama, Qwen, Mistral, …) | MIT |
| [Open WebUI](https://github.com/open-webui/open-webui) | ChatGPT-style web interface | BSD-3 |

---

## Quick start

Requires [Docker](https://docs.docker.com/get-docker/) (Docker Desktop on
Windows/Mac, Docker Engine on Linux).

```bash
cd stack
cp .env.example .env      # optional — defaults work out of the box
./start.sh                # brings everything up + pulls the default model
```

Then open **http://localhost:3000**, create your first account (it becomes the
admin), pick a model, and start chatting.

Prefer to do it by hand instead of `start.sh`:

```bash
docker compose up -d
docker compose exec ollama ollama pull llama3.2:3b
```

---

## Choosing a model

Pull any model from the [Ollama library](https://ollama.com/library). Set
`DEFAULT_MODEL` in `.env`, or pull more anytime with
`docker compose exec ollama ollama pull <model>`.

| Model | Size | Good for |
|-------|------|----------|
| `qwen2.5:0.5b` | ~0.4 GB | Low-RAM machines, quick tests |
| `llama3.2:3b` | ~2 GB | **Default** — solid on a typical laptop |
| `llama3.1:8b` | ~4.7 GB | Stronger answers (needs ~8 GB+ RAM) |
| `mistral:7b` | ~4.1 GB | General-purpose alternative |

CPU-only works. For an **NVIDIA GPU**, install the
[nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
and uncomment the `deploy:` block in `docker-compose.yml`.

---

## Everyday commands

```bash
docker compose ps           # status
docker compose logs -f      # live logs
docker compose down         # stop (data is kept in named volumes)
docker compose pull         # update to the latest images
```

Your chats, accounts, and downloaded models persist in the `ollama_data` and
`open_webui_data` Docker volumes across restarts.

---

## Running on your Windows desktop via Desktop Commander

The `baseline_audit.ps1` script shows the target machine is Windows. To run
this stack there:

1. Install **Docker Desktop for Windows** and make sure it's running.
2. From the repo folder, in PowerShell:
   ```powershell
   cd stack
   docker compose up -d
   docker compose exec ollama ollama pull llama3.2:3b
   ```
3. Open http://localhost:3000.

(`start.sh` is a bash script — on Windows use the PowerShell commands above, or
run it from WSL/Git Bash.)

---

## Restricted or air-gapped networks

On a locked-down network (some farms, rural ISPs, or corporate firewalls),
`ollama pull` may not be able to reach the model registry. You can still run
fully sovereign — get a `.gguf` model file in by any route your network allows
(a USB stick, an internal mirror, or Docker Hub's `ai/` model namespace, which
many firewalls permit) and register it locally:

```bash
./import-gguf.sh /path/to/model.gguf my-model:tag
```

Example using Docker Hub's model namespace (works wherever `docker pull` does):

```bash
docker pull ai/smollm2:360M-Q4_K_M            # downloads the GGUF layer
# ...locate the pulled .gguf, then:
./import-gguf.sh ./smollm2-360m.gguf smollm2:360m
```

The helper uses a ChatML prompt template (fits SmolLM2, Qwen2.5, and most
modern instruct models); edit the template inside `import-gguf.sh` for models
that use a different format.

---

## Why this is the "sovereign" layer

The tools listed in the root `README.md` (Perplexity, Monica, Merlin, …) are
convenient but are **paid, external SaaS** — your data goes to their servers and
the "$0" only holds on free tiers. This Docker stack is the part that delivers
on the project's actual promise: **open-source, self-hosted, $0, no vendor
lock-in, your data stays on your hardware.**

Built with 🌽 in Iowa.
