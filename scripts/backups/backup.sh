#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

BACKUP_DIR="/opt/backups"
DATE=$(date +%F_%H-%M-%S)
DB_VOLUME="remnawave-db-data"
REMWAVE_DIR="/opt/remnawave"

DB_TAR="remnawave-db-backup-$DATE.tar.gz"
FINAL_ARCHIVE="remnawave-backup-$DATE.7z"

mkdir -p "$BACKUP_DIR"

for cmd in docker tar p7zip; do
  if ! command -v $cmd &>/dev/null; then
    warn "$cmd не найден. Пытаюсь установить..."
    if command -v apt-get &>/dev/null; then
      sudo apt-get update
      if [ "$cmd" = "p7zip" ]; then
        sudo apt-get install -y p7zip-full
      else
        sudo apt-get install -y $cmd
      fi
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
  error "Docker volume $DB_VOLUME не найден! Нет данных для бэкапа."
  read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1
fi

if [ ! -d "$REMWAVE_DIR" ]; then
  error "Директория $REMWAVE_DIR не найдена! Нет данных для бэкапа."
  read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1
fi

if [ ! -f "$REMWAVE_DIR/.env" ]; then
  error "Файл .env не найден в $REMWAVE_DIR! Нет данных для бэкапа."
  read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1
fi

if [ ! -f "$REMWAVE_DIR/docker-compose.yml" ]; then
  error "Файл docker-compose.yml не найден в $REMWAVE_DIR! Нет данных для бэкапа."
  read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1
fi

info "Бэкап тома $DB_VOLUME..."
docker run --rm \
  -v ${DB_VOLUME}:/volume \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czf /backup/$DB_TAR -C /volume .

info "Бэкап конфигурационных файлов..."
cp "$REMWAVE_DIR/.env" "$BACKUP_DIR/"
cp "$REMWAVE_DIR/docker-compose.yml" "$BACKUP_DIR/"

while true; do
  question "Введите пароль для архива (минимум 8 символов):"
  read -s ARCHIVE_PASSWORD
  if [ ${#ARCHIVE_PASSWORD} -ge 8 ]; then
    break
  else
    warn "Пароль должен содержать минимум 8 символов"
  fi
done

info "Создание финального архива с паролем..."
7z a -t7z -m0=lzma2 -mx=9 -mfb=273 -md=64m -ms=on -p"$ARCHIVE_PASSWORD" "$BACKUP_DIR/$FINAL_ARCHIVE" "$BACKUP_DIR/$DB_TAR" "$BACKUP_DIR/.env" "$BACKUP_DIR/docker-compose.yml"

rm "$BACKUP_DIR/$DB_TAR" "$BACKUP_DIR/.env" "$BACKUP_DIR/docker-compose.yml"

success "Бэкап готов: $BACKUP_DIR/$FINAL_ARCHIVE"
read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
exit 0