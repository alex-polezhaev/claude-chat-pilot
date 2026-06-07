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
# старте из переменных окружения, идемпотентно. Подключаем наш MCP-сервер
# diamdor-content, предодобряем его (без окон Allow) и кладём инструкцию CLAUDE.md.
mkdir -p /workspace/main/.claude

# MCP-сервер: HTTP + Bearer-токен из env. Кавычки на EOF НЕ ставим — нужны подстановки.
cat > /workspace/main/.mcp.json <<EOF
{"mcpServers":{"diamdor-content":{"type":"http","url":"${CONTENT_MCP_URL}","headers":{"Authorization":"Bearer ${CONTENT_MCP_TOKEN}"}}}}
EOF

# Предодобрение всех project-MCP-серверов (окно Allow не появится).
cat > /workspace/main/.claude/settings.json <<'EOF'
{"enableAllProjectMcpServers":true}
EOF

# Инструкция для агента: работать ТОЛЬКО через MCP diamdor-content, без локальных файлов.
cat > /workspace/main/CLAUDE.md <<'EOF'
# Рабочая среда контент-менеджера diamdor.ru

Это рабочая среда контент-менеджера diamdor.ru. Все темы, статьи и раскадровки
живут В БАЗЕ и доступны ТОЛЬКО через инструменты MCP-сервера **diamdor-content**
(`list_topics`, `get_storyboard`, `create_topic`, `create_video`, `add_frame`,
`update_frame`, `delete_frame`, `reorder_frame`, `get_progress`).

Правила:
- НИКОГДА не создавай локальные файлы (`.md` и т.п.) и не читай их — это не нужно.
- Не запускай `ls` или чтение `MEMORY.md` без явной причины.
- Если просят завести тему или кадр — используй соответствующий MCP-инструмент.
- Отвечай кратко.
EOF

exec cloudcli start
