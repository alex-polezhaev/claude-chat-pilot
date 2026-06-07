#!/bin/sh
set -e

# При первом запуске создаём готовую рабочую папку (git-репозиторий),
# чтобы в интерфейсе сразу был проект и сотруднику не нужно было
# ничего выбирать вручную. Папка лежит в постоянном томе /workspace.
if [ ! -d /workspace/main/.git ]; then
  mkdir -p /workspace/main
  cd /workspace/main
  git init -q
  printf '# Рабочая папка\n\nЗдесь сотрудник работает с Claude.\n' > README.md
  git -c user.email=agent@diamdor.ru -c user.name=agent add -A
  git -c user.email=agent@diamdor.ru -c user.name=agent commit -qm "init workspace" || true
fi

# Конфиг рабочей среды Claude (НЕ контент сотрудника) — перегенерируем при каждом
# старте, идемпотентно. Подключаем наш MCP-сервер diamdor-content, предодобряем его
# (без окон Allow) и кладём инструкцию CLAUDE.md.
mkdir -p /workspace/main/.claude

# MCP-сервер: HTTP + Bearer-токен из env. Кавычки на EOF НЕ ставим — нужны подстановки.
cat > /workspace/main/.mcp.json <<EOF
{"mcpServers":{"diamdor-content":{"type":"http","url":"${CONTENT_MCP_URL}","headers":{"Authorization":"Bearer ${CONTENT_MCP_TOKEN}"}}}}
EOF

# Предодобрение всех project-MCP-серверов (окно Allow не появится).
cat > /workspace/main/.claude/settings.json <<'EOF'
{"enableAllProjectMcpServers":true}
EOF

# Инструкция для агента (CLAUDE.md) — ЕДИНЫЙ источник: файл CLAUDE.md в репозитории,
# вшит в образ (Dockerfile COPY → /usr/local/share/CLAUDE.md). Правишь CLAUDE.md →
# push → redeploy. Без heredoc-дублей.
cp /usr/local/share/CLAUDE.md /workspace/main/CLAUDE.md

exec cloudcli start
