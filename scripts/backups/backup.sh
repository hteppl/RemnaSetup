#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

BACKUP_DIR="/opt/backups"
DATE=$(date +%F_%H-%M-%S)
DB_VOLUME="remnawave-db-data"
REMWAVE_DIR="/opt/remnawave"

DB_TAR="remnawave-db-backup-$DATE.tar.gz"
FINAL_ARCHIVE="remnawave-backup-$DATE.7z"
TMP_DIR="$BACKUP_DIR/tmp-$DATE"

mkdir -p "$BACKUP_DIR"

while true; do
  question "Введите пароль для архива (минимум 8 символов):"
  ARCHIVE_PASSWORD="$REPLY"
  if [ ${#ARCHIVE_PASSWORD} -ge 8 ]; then
    break
  else
    warn "Пароль должен содержать минимум 8 символов"
  fi
done

echo

for cmd in docker tar 7z; do
  if ! command -v $cmd &>/dev/null; then
    warn "$cmd не найден. Пытаюсь установить..."
    if command -v apt-get &>/dev/null; then
      sudo apt-get update
      if [ "$cmd" = "7z" ]; then
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

mkdir -p "$TMP_DIR"

info "Бэкап тома $DB_VOLUME..."
docker run --rm \
  -v ${DB_VOLUME}:/volume \
  -v "$TMP_DIR":/backup \
  alpine \
  tar czf /backup/$DB_TAR -C /volume .

info "Бэкап конфигурационных файлов..."
cp "$REMWAVE_DIR/.env" "$TMP_DIR/"
cp "$REMWAVE_DIR/docker-compose.yml" "$TMP_DIR/"

info "Создание финального архива с паролем..."
7z a -t7z -m0=lzma2 -mx=9 -mfb=273 -md=64m -ms=on -p"$ARCHIVE_PASSWORD" "$BACKUP_DIR/$FINAL_ARCHIVE" "$TMP_DIR/*" >/dev/null 2>&1
if [ $? -ne 0 ]; then
  error "Ошибка создания архива! Проверьте наличие 7z и права на запись."
  ls -l "$TMP_DIR"
  rm -rf "$TMP_DIR"
  exit 1
fi

rm -rf "$TMP_DIR"

success "Бэкап готов: $BACKUP_DIR/$FINAL_ARCHIVE"
read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
exit 0