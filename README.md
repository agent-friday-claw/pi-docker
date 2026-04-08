# pi-docker

Minimal Docker image for [Pi coding agent](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent) by badlogic.

Image built via GitHub Actions → GHCR.

## Usage

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -e ANTHROPIC_API_KEY=sk-ant-... \
  ghcr.io/<your-username>/pi-docker:latest
```

Or with OpenAI:

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -e OPENAI_API_KEY=sk-... \
  ghcr.io/<your-username>/pi-docker:latest
```

**Flags:**
- `-it` — required, Pi is a TUI
- `-v $(pwd):/workspace` — mounts your current directory as the workspace Pi operates on
- `-e` — pass your API key(s) as env vars

## Pi settings persistence

Pi stores settings and session history in `~/.pi` inside the container (ephemeral by default).
To persist across runs, mount a volume:

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -v $HOME/.pi:/root/.pi \
  -e ANTHROPIC_API_KEY=sk-ant-... \
  ghcr.io/<your-username>/pi-docker:latest
```
