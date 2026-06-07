# Пилот: веб-чат Claude для сотрудника.
# Образ = Claude Code CLI (авторизация по подписке через CLAUDE_CODE_OAUTH_TOKEN)
#       + веб-интерфейс с логином (@cloudcli-ai/cloudcli, он же claudecodeui).
FROM node:22-bookworm-slim

# Инструменты для сборки нативного модуля node-pty (нужен интерфейсу) + git/rg.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git ca-certificates python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

# Сам Claude и веб-интерфейс.
RUN npm install -g @anthropic-ai/claude-code @cloudcli-ai/cloudcli \
    && cloudcli version

ENV HOST=0.0.0.0 \
    SERVER_PORT=3001 \
    CLAUDE_CLI_PATH=claude \
    DATABASE_PATH=/data/auth.db \
    WORKSPACES_ROOT=/workspace

# /data — логины и настройки интерфейса; /workspace — рабочая папка сотрудника.
RUN mkdir -p /data /workspace
WORKDIR /workspace

# При старте создаём готовую рабочую папку, чтобы в интерфейсе сразу был проект.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3001
CMD ["/usr/local/bin/entrypoint.sh"]
