# ---- Stage 1: Build Python MCP Server ----
FROM node:22-slim AS py-builder

ARG GH="https://github.com"
ARG MCP_REPO="uukelele/scratch-mcp.git"

RUN apt-get update && apt-get install -y git python3 ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

WORKDIR /src
RUN git clone "${GH}/${MCP_REPO}" . \
    && uv venv --python /usr/bin/python3 \
    && uv sync --frozen

# ---- Stage 2: Build Rust Toolchain (goboscript & sb2gs) ----
FROM rustlang/rust:nightly-bookworm-slim AS rust-builder

ARG GH="https://github.com"
ARG GOBO_REPO="aspizu/goboscript"
ARG SB2GS_REPO="aspizu/sb2gs"

RUN apt-get update && apt-get install -y git pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

RUN cargo install --git "${GH}/${GOBO_REPO}" \
    && cargo install --git "${GH}/${SB2GS_REPO}" sb2gs-cli

# ---- Stage 3: Main Runtime Image ----
FROM node:22-slim

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

# Copy compiled Rust binaries from Stage 2
COPY --from=rust-builder /usr/local/cargo/bin/goboscript /usr/local/bin/goboscript
COPY --from=rust-builder /usr/local/cargo/bin/sb2gs /usr/local/bin/sb2gs

# Copy Python MCP server and .venv from Stage 1
COPY --from=py-builder /src /opt/scratch-mcp

# Backup MCP configuration template
RUN mkdir -p /opt/scratch-mcp/config && echo '{ \
  "mcpServers": { \
    "scratch": { \
      "command": "/opt/scratch-mcp/.venv/bin/python", \
      "args": ["-m", "scratch_mcp"], \
      "cwd": "/opt/scratch-mcp", \
      "env": { \
        "PYTHONPATH": "/opt/scratch-mcp" \
      }, \
      "timeout": 600000 \
    } \
  } \
}' > /opt/scratch-mcp/config/mcp.json

WORKDIR /pi-workspace
SHELL ["/bin/bash", "-c"]

CMD ["pi"]
