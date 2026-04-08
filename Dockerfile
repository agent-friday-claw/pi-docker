# ---- Base ----
FROM node:20-slim

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
    && rm -rf /var/lib/apt/lists/*

# ---- Install Pi coding agent ----
RUN npm install -g @mariozechner/pi-coding-agent

# ---- Workspace ----
WORKDIR /workspace

SHELL ["/bin/bash", "-c"]

# Pi is a TUI — needs TTY at runtime (docker run -it)
CMD ["pi"]
