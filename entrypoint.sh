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

exec cloudcli start
