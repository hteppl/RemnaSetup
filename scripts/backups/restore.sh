#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

BACKUP_DIR="/opt/backups"
WORK_DIR="$BACKUP_DIR/restore_work"
DATE=$(date +%F_%H-%M-%S)
DB_VOLUME="remnawave-db-data"
REDIS_VOLUME="remnawave-redis-data"
DB_CONTAINER="remnawave-db"
REDIS_CONTAINER="remnawave-redis"
PANEL_CONTAINER="remnawave"

info "Восстановление Remnawave из бэкапа"

for v in $DB_VOLUME $REDIS_VOLUME; do
  if ! docker volume inspect $v &>/dev/null; then
    error "Docker volume $v не найден! Проверьте, что Remnawave установлен."
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1
  fi
done
for c in $DB_CONTAINER $REDIS_CONTAINER $PANEL_CONTAINER; do
  if ! docker ps -a --format '{{.Names}}' | grep -qw "$c"; then
    error "Контейнер $c не найден! Проверьте, что Remnawave установлен."
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1
  fi
done

mkdir -p "$BACKUP_DIR"
info "Папка $BACKUP_DIR создана. Пожалуйста, положите архив в эту папку и нажмите любую клавишу для продолжения."
read -n 1 -s -r -p "Нажмите любую клавишу для продолжения..."
echo

while true; do
  mapfile -t ARCHIVES < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'remnawave-backup-*.tar.gz' | sort)
  if [[ ${#ARCHIVES[@]} -eq 0 ]]; then
    warn "В папке $BACKUP_DIR не найдено архивов бэкапа. Положите нужный архив в эту папку."
    echo "Нажмите любую клавишу для продолжения или n для отмены."
    read -n 1 -s KEY
    if [[ "$KEY" == "n" || "$KEY" == "N" ]]; then
      info "Выход из восстановления."
      exit 0
    fi
  else
    break
  fi
done

echo "Доступные бэкапы:"
for i in "${!ARCHIVES[@]}"; do
  echo "$((i+1)). ${ARCHIVES[$i]}"
done

while true; do
  read -p "Введите номер бэкапа для восстановления: " CHOICE
  if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#ARCHIVES[@]} )); then
    ARCHIVE_PATH="${ARCHIVES[$((CHOICE-1))]}"
    info "Выбран архив: $ARCHIVE_PATH"
    break
  else
    warn "Некорректный выбор. Попробуйте снова."
  fi
done

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

info "Копирование архива в рабочую папку..."
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cp "$ARCHIVE_PATH" "$WORK_DIR/"
ARCHIVE_BASENAME=$(basename "$ARCHIVE_PATH")
WORK_ARCHIVE="$WORK_DIR/$ARCHIVE_BASENAME"
success "Архив скопирован: $WORK_ARCHIVE"

info "Создаю резервную копию текущих данных..."
RESERVE_DB="remnawave-db-backup-before-restore-$DATE.tar.gz"
RESERVE_REDIS="remnawave-redis-backup-before-restore-$DATE.tar.gz"
RESERVE_ARCHIVE="remnawave-backup-before-restore-$DATE.tar.gz"

docker run --rm \
  -v ${DB_VOLUME}:/volume \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czvf /backup/$RESERVE_DB -C /volume .
docker run --rm \
  -v ${REDIS_VOLUME}:/volume \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czvf /backup/$RESERVE_REDIS -C /volume .
tar czvf "$BACKUP_DIR/$RESERVE_ARCHIVE" -C "$BACKUP_DIR" "$RESERVE_DB" "$RESERVE_REDIS"
rm "$BACKUP_DIR/$RESERVE_DB" "$BACKUP_DIR/$RESERVE_REDIS"
success "Резервная копия текущих данных: $BACKUP_DIR/$RESERVE_ARCHIVE"

info "Останавливаю контейнеры Remnawave..."
docker stop $PANEL_CONTAINER $DB_CONTAINER $REDIS_CONTAINER 2>/dev/null
success "Контейнеры остановлены."

info "Распаковка архива в рабочую папку..."
TMP_RESTORE_DIR="$WORK_DIR/unpack"
mkdir -p "$TMP_RESTORE_DIR"
tar xzvf "$WORK_ARCHIVE" -C "$TMP_RESTORE_DIR"
success "Архив распакован."

info "Восстанавливаю том $DB_VOLUME..."
docker run --rm \
  -v ${DB_VOLUME}:/volume \
  -v "$TMP_RESTORE_DIR":/backup \
  alpine \
  sh -c "rm -rf /volume/* && tar xzvf /backup/remnawave-db-backup-*.tar.gz -C /volume"
success "Том $DB_VOLUME восстановлен."

info "Восстанавливаю том $REDIS_VOLUME..."
docker run --rm \
  -v ${REDIS_VOLUME}:/volume \
  -v "$TMP_RESTORE_DIR":/backup \
  alpine \
  sh -c "rm -rf /volume/* && tar xzvf /backup/remnawave-redis-backup-*.tar.gz -C /volume"
success "Том $REDIS_VOLUME восстановлен."

info "Удаляю рабочую папку восстановления..."
rm -rf "$WORK_DIR"
success "Рабочая папка удалена."

info "Запускаю контейнеры Remnawave..."
docker start $DB_CONTAINER $REDIS_CONTAINER $PANEL_CONTAINER 2>/dev/null
success "Контейнеры запущены."

success "Восстановление завершено!"
read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
exit 0 