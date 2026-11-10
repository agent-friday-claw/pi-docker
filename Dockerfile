# ---- Stage 1: Build goboscript (Rust, needs nightly) ----
# Pinned to bookworm to match the runtime image's glibc / libssl.
FROM rustlang/rust:nightly-bookworm-slim AS rust-builder

ARG GH="https://github.com"
ARG GOBO_REPO="aspizu/goboscript"

RUN apt-get update && apt-get install -y git pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

# --locked uses goboscript's Cargo.lock so dependency drift can't break the build
RUN cargo install --locked --git "${GH}/${GOBO_REPO}"

# ---- Stage 2: Main Runtime Image ----
FROM node:22-bookworm-slim

ARG GH="https://github.com"
ARG MCP_REPO="uukelele/scratch-mcp.git"
ARG SB2GS_REPO="aspizu/sb2gs"

RUN apt-get update && apt-get install -y \
    git \
    bash \
    curl \
    vim \
    build-essential \
    python3 \
    python3-pip \
    ca-certificates \
    espeak-ng \
    && rm -rf /var/lib/apt/lists/*

# Install Pi coding agent
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# ---- uv: provides the Python versions the Scratch tools need ----
# Debian's python3 is 3.11; scratch-mcp needs >=3.12 and sb2gs needs >=3.14.
# Use uv-managed interpreters at fixed paths so they exist at runtime.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python \
    UV_PYTHON_PREFERENCE=only-managed \
    UV_TOOL_DIR=/opt/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    UV_LINK_MODE=copy

# sb2gs (goboscript decompiler) is a Python package, not a Rust crate
RUN uv tool install --python 3.14 "git+${GH}/${SB2GS_REPO}"

# goboscript (compiler) from Stage 1
COPY --from=rust-builder /usr/local/cargo/bin/goboscript /usr/local/bin/goboscript

# Scratch MCP server
RUN git clone "${GH}/${MCP_REPO}" /opt/scratch-mcp \
    && cd /opt/scratch-mcp \
    && uv sync --frozen --no-dev --python 3.12

# Preview helper: serves .sb3 files on port 3000 for TurboWarp
COPY scratch-preview /usr/local/bin/scratch-preview
RUN chmod +x /usr/local/bin/scratch-preview

# Backup MCP configuration template (timeout is in seconds for Pi)
RUN mkdir -p /opt/scratch-mcp/config && echo '{ \
  "mcpServers": { \
    "scratch": { \
      "command": "/opt/scratch-mcp/.venv/bin/python", \
      "args": ["-m", "scratch_mcp"], \
      "cwd": "/opt/scratch-mcp", \
      "env": { \
        "PYTHONPATH": "/opt/scratch-mcp", \
        "SCRATCH_MCP_DATA_DIR": "/root/.pi/scratch-mcp" \
      }, \
      "timeout": 600 \
    } \
  } \
}' > /opt/scratch-mcp/config/mcp.json

WORKDIR /pi-workspace
SHELL ["/bin/bash", "-c"]

CMD ["pi"]
