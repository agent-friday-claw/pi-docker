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
WORKDIR /opt/scratch-mcp-server
RUN npm install @unom-technology/scratch-mcp-server \
    && chmod -R 755 /opt/scratch-mcp-server

# ---- Create an In-Image Backup Config ----
# Since /root/.pi gets completely covered by your Mac volume mount,
# we place the configuration file here as a fallback template.
RUN mkdir -p /opt/scratch-mcp-server/config && echo '{ \
  "mcpServers": { \
    "scratch": { \
      "command": "node", \
      "args": ["/opt/scratch-mcp-server/node_modules/@unom-technology/scratch-mcp-server/dist/index.js"], \
      "env": { \
        "SCRATCH_MCP_OUT_DIR": "/pi-workspace/scratch-projects" \
      } \
    } \
  } \
}' > /opt/scratch-mcp-server/config/mcp.json

WORKDIR /pi-workspace
SHELL ["/bin/bash", "-c"]

CMD ["pi"]
