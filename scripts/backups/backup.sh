#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

BACKUP_DIR="/opt/backups"
DATE=$(date +%F_%H-%M-%S)
DB_VOLUME="remnawave-db-data"
REDIS_VOLUME="remnawave-redis-data"

DB_TAR="remnawave-db-backup-$DATE.tar.gz"
REDIS_TAR="remnawave-redis-backup-$DATE.tar.gz"
FINAL_ARCHIVE="remnawave-backup-$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR" || { error "Не удалось перейти в $BACKUP_DIR"; read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1; }

for cmd in docker tar; do
  if ! command -v $cmd &>/dev/null; then
    warn "$cmd не найден. Пытаюсь установить..."
    if command -v apt-get &>/dev/null; then
      sudo apt-get update && sudo apt-get install -y $cmd
    elif command -v yum &>/dev/null; then
      sudo yum install -y $cmd
    elif command -v apk &>/dev/null; then
      sudo apk add $cmd
    else
      error "Не удалось установить $cmd. Установите вручную."
      read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1
    fi
    if ! command -v $cmd &>/dev/null; then
      error "$cmd не установлен. Установите вручную."
      read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1
    fi
  fi
done

if ! docker volume inspect $DB_VOLUME &>/dev/null; then
  error "Docker volume $DB_VOLUME не найден!"
  read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1
fi
if ! docker volume inspect $REDIS_VOLUME &>/dev/null; then
  error "Docker volume $REDIS_VOLUME не найден!"
  read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1
fi

info "Бэкап тома $DB_VOLUME..."
docker run --rm \
  -v ${DB_VOLUME}:/volume \
  -v "$(pwd)":/backup \
  alpine \
  tar czvf /backup/$DB_TAR -C /volume .

info "Бэкап тома $REDIS_VOLUME..."
docker run --rm \
  -v ${REDIS_VOLUME}:/volume \
  -v "$(pwd)":/backup \
  alpine \
  tar czvf /backup/$REDIS_TAR -C /volume .

info "Архивация..."
tar czvf "$FINAL_ARCHIVE" "$DB_TAR" "$REDIS_TAR"

rm "$DB_TAR" "$REDIS_TAR"

success "Бэкап готов: $BACKUP_DIR/$FINAL_ARCHIVE"
read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
exit 0