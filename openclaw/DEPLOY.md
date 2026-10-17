# 🚀 Deploying OpenClaw somewhere it stays on

The cloud session where this was built is **ephemeral** — anything running there
disappears when it idles. To actually *use* OpenClaw (open the UI, connect chat
apps, have it answer any time), run it somewhere persistent. Two paths:

- **A) Your Windows PC** — easiest; runs while your PC is on.
- **B) A cheap/free always-on host** — runs 24/7 without your PC.

Everything here is **CPU-only — no GPU required**. More RAM = bigger/faster
models.

---

## A) Run on your Windows PC

1. Install **[Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)**
   and start it (wait until the whale icon says "running").
2. Get this repo (Git, or "Download ZIP" from GitHub and unzip).
3. Open **PowerShell** in the repo folder and run:

   ```powershell
   # 1) Start the free local model engine and pull a model
   cd stack
   docker compose up -d
   docker compose exec ollama ollama pull qwen2.5:3b

   # 2) Set a gateway token, then start OpenClaw
   cd ..\openclaw
   Copy-Item .env.example .env
   # edit .env and set a long random value for OPENCLAW_GATEWAY_TOKEN
   docker compose up -d
   ```

4. Open **http://localhost:18789** and pair with the token from `.env`.

Stop with `docker compose down` (in each folder). Your data persists in Docker
volumes. On a low-RAM PC, use a smaller model: `ollama pull qwen2.5:1.5b` (or
`smollm2:360m`) and set it as `primary` in `openclaw/openclaw.json`.

> `start.sh` automates steps 1–3 but is a bash script — run it from **WSL** or
> **Git Bash**, or just use the PowerShell commands above.

---

## B) Cheap / free always-on host

So OpenClaw runs 24/7 even when your PC is off. All options below are CPU
(no GPU); pick by budget.

| Option | Cost | Notes |
|--------|------|-------|
| **Oracle Cloud "Always Free" (Ampere ARM VM)** | **$0** | Best free pick. ~2 OCPU / 12 GB RAM + 200 GB disk (was 4/24 — Oracle trimmed it in 2026; **verify current terms**). 12 GB easily runs a 7B model on CPU. ARM capacity can be "out of stock" in popular regions — retry or pick another region. |
| **Low-cost VPS** (Hetzner, Contabo, etc.) | ~€4–6/mo | Dependable, no capacity lottery. Pick 8 GB+ RAM for 7B models. |
| **Old PC / mini-PC / Raspberry Pi 5 at home** | $0 (hardware you own) | Fully sovereign. A Pi 5 (8 GB) runs small models slowly; an old desktop does better. |

### Generic VPS/VM setup (Ubuntu)

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker

# Get the repo and start everything
git clone https://github.com/Ark95x-sAn/Iowa-AI-Sovereignty-Stack.git
cd Iowa-AI-Sovereignty-Stack/stack
docker compose up -d
docker compose exec ollama ollama pull qwen2.5:3b   # or a 7B on a 12GB+ box

cd ../openclaw
cp .env.example .env     # set a strong OPENCLAW_GATEWAY_TOKEN
./start.sh
```

Both `stack` and `openclaw` have `restart: unless-stopped`, so they come back
automatically after a reboot.

### Securing it (do this — it's exposed to the internet)

- **Set a long random `OPENCLAW_GATEWAY_TOKEN`** and keep it secret.
- **Do NOT open port 18789 to the whole internet.** Instead, reach it privately:
  - **[Tailscale](https://tailscale.com)** (free) — put the server and your
    devices on one private network; access `http://<tailscale-ip>:18789`. Easiest
    and recommended.
  - or an SSH tunnel: `ssh -L 18789:localhost:18789 user@server`.
  - or a reverse proxy (Caddy/Traefik) with HTTPS + auth if you truly need public
    access; set `gateway.publicOrigin` accordingly.
- Keep the host firewall closed except SSH (and Tailscale).

---

## Picking a model for the host's RAM

| RAM | Good model | Pull command |
|-----|-----------|--------------|
| ~4 GB | `qwen2.5:1.5b` / `smollm2:360m` | `ollama pull qwen2.5:1.5b` |
| ~8 GB | `qwen2.5:3b` (default) | `ollama pull qwen2.5:3b` |
| 12 GB+ | `qwen2.5:7b` / `llama3.1:8b` | `ollama pull qwen2.5:7b` |

After pulling, set it as `agents.defaults.model.primary` (and add it under the
`ollama` provider's `models`) in `openclaw/openclaw.json`, then
`docker compose restart openclaw-gateway`.

Built with 🌽 in Iowa.
