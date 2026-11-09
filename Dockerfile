# ---- Base ----
FROM node:22-slim

# ---- System deps ----
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

# ---- Install Pi coding agent ----
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# ---- Install Scratch MCP Server via NPM ----
# This replaces the git clone method with a stable, versioned package registry download
WORKDIR /opt/scratch-mcp-server
RUN npm install @unom-technology/scratch-mcp-server \
    && chmod -R 755 /opt/scratch-mcp-server

# ---- Setup Non-Root User ----
RUN useradd -m -s /bin/bash developer

# ---- Pre-register MCP Config for the Developer User ----
RUN mkdir -p /home/developer/.pi/agent && echo '{ \
  "mcpServers": { \
    "scratch": { \
      "command": "node", \
      "args": ["/opt/scratch-mcp-server/node_modules/@unom-technology/scratch-mcp-server/dist/index.js"], \
      "env": { \
        "SCRATCH_MCP_OUT_DIR": "/workspace/scratch-projects" \
      } \
    } \
  } \
}' > /home/developer/.pi/agent/mcp.json \
    && chown -R developer:developer /home/developer/.pi

# ---- Workspace ----
WORKDIR /workspace
RUN mkdir -p /workspace/scratch-projects && chown -R developer:developer /workspace

# Switch context to the non-root user
USER developer

SHELL ["/bin/bash", "-c"]

# Pi is a TUI — needs TTY at runtime (docker run -it)
CMD ["pi"]
