# pi-docker

Minimal Docker image for [Pi coding agent](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent) by [@badlogic](https://github.com/badlogic).

Built via GitHub Actions and published to GHCR.

## Quick start

**1. Clone this repo (or just grab the `pi` script and `.env.example`):**

```bash
git clone https://github.com/agent-friday-claw/pi-docker.git
cd pi-docker
```

**2. Set up your API key:**

```bash
cp .env.example .env
# edit .env and fill in ANTHROPIC_API_KEY (or whichever provider you use)
```

**3. Run Pi from any project directory:**

```bash
# Make the script executable (once)
chmod +x /path/to/pi-docker/pi

# Then run from your project
cd ~/my-project
/path/to/pi-docker/pi
```

Pi will open with `/workspace` mapped to your current directory.

---

## The `pi` script

The `pi` script is a convenience wrapper around `docker run`. It:

- Loads API keys from a `.env` file in the same directory as the script
- Mounts your **current working directory** as `/workspace` inside the container
- Persists Pi's settings and session history to `~/.pi` on your host

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
PI_CONFIG="$HOME/.pi"

mkdir -p "$PI_CONFIG"

docker run -it --rm \
  --env-file "$ENV_FILE" \
  -v "$(pwd):/workspace" \
  -v "$PI_CONFIG:/root/.pi" \
  -w /workspace \
  ghcr.io/agent-friday-claw/pi-docker:latest
```

### Tip: add it to your PATH

For convenient access from anywhere:

```bash
# In ~/.bashrc or ~/.zshrc
export PATH="/path/to/pi-docker:$PATH"
```

Then just run `pi` from any directory.

---

## Manual `docker run`

If you'd rather run the container directly:

```bash
docker run -it --rm \
  -e ANTHROPIC_API_KEY=sk-ant-... \
  -v $(pwd):/workspace \
  -v $HOME/.pi:/root/.pi \
  -w /workspace \
  ghcr.io/agent-friday-claw/pi-docker:latest
```

---

## Image details

- **Base:** `node:20-slim`
- **Package:** `@mariozechner/pi-coding-agent` (latest at build time)
- **Platforms:** `linux/amd64`, `linux/arm64`
- **Default command:** `pi`

The image is rebuilt automatically on every push to `main`.

---

## Providers

Pi supports multiple providers via API key or subscription login (`/login` inside Pi):

| Provider | Env var |
|---|---|
| Anthropic Claude | `ANTHROPIC_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| Google Gemini | `GEMINI_API_KEY` |
| GitHub Copilot | via `/login` |

---

## Pi config persistence

Pi stores settings and session history in `~/.pi`. The `pi` script mounts `$HOME/.pi` on your host to `/root/.pi` in the container, so your sessions persist across runs automatically.
