# ---- Stage 1: Build the Scratch MCP Server ----
FROM node:22-slim AS builder

RUN apt-get update && apt-get install -y git ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /src
# Clone the repository and build the TypeScript distribution bundle locally
RUN git clone https://github.com . \
    && npm install \
    && npm run build

# ---- Stage 2: Main Image Runtime ----
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

# ---- Copy compiled server files from builder stage ----
WORKDIR /opt/scratch-mcp-server
COPY --from=builder /src/dist ./dist
COPY --from=builder /src/node_modules ./node_modules
COPY --from=builder /src/package.json ./package.json

RUN chmod -R 755 /opt/scratch-mcp-server

# ---- Create an In-Image Backup Config ----
RUN mkdir -p /opt/scratch-mcp-server/config && echo '{ \
  "mcpServers": { \
    "scratch": { \
      "command": "node", \
      "args": ["/opt/scratch-mcp-server/dist/index.js"], \
      "env": { \
        "SCRATCH_MCP_OUT_DIR": "/pi-workspace/scratch-projects" \
      } \
    } \
  } \
}' > /opt/scratch-mcp-server/config/mcp.json

WORKDIR /pi-workspace
SHELL ["/bin/bash", "-c"]

CMD ["pi"]
