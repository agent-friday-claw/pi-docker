# ---- Stage 1: Build & Prep Scratch MCP Server ----
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

WORKDIR /src
# Clone the real Python-based scratch-mcp repository
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/uukelele/scratch-mcp.git .

# Sync dependencies using uv into a local virtual environment (.venv)
RUN uv sync --frozen

# ---- Stage 2: Main Image Runtime ----
FROM node:22-slim

# ---- System dependencies (Node, Python, and Rust Toolchain) ----
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

# Install the Rust compiler required by the goboscript toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install the required goboscript compiler and sb2gs decompiler tools via Cargo
RUN rustup toolchain install nightly \
    && cargo +nightly install --git https://github.com \
    && cargo install --git https://github.com sb2gs-cli

# ---- Install Pi coding agent ----
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# ---- Copy Python MCP environment from builder stage ----
COPY --from=builder /src /opt/scratch-mcp

# ---- Create an In-Image Backup Config ----
# Paths configured to target the Python module execution context
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
