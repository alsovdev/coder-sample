FROM mcr.microsoft.com/devcontainers/javascript-node:20-bookworm

# Python для Airflow CLI и общие утилиты
RUN apt-get update && apt-get install -y \
    python3-pip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Глобальные Node.js пакеты
RUN npm install -g pnpm tsx

WORKDIR /home/coder/project
