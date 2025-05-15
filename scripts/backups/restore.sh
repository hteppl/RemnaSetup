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

get_telegram_backups() {
    local bot_token=$1
    local chat_id=$2
    local temp_file="/tmp/telegram_backups.json"

    curl -s "https://api.telegram.org/bot${bot_token}/getUpdates?chat_id=${chat_id}&limit=5" > "$temp_file"

    local backups=()
    while IFS= read -r line; do
        if [[ $line =~ remnawave-backup-[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}\.tar\.gz ]]; then
            backups+=("$line")
        fi
    done < <(jq -r '.result[].message.document.file_name' "$temp_file" 2>/dev/null)
    
    rm -f "$temp_file"
    echo "${backups[@]}"
}

download_telegram_backup() {
    local bot_token=$1
    local chat_id=$2
    local file_name=$3
    local temp_file="/tmp/telegram_file.json"

    curl -s "https://api.telegram.org/bot${bot_token}/getUpdates?chat_id=${chat_id}&limit=5" > "$temp_file"
    local file_id=$(jq -r --arg name "$file_name" '.result[].message.document | select(.file_name == $name) | .file_id' "$temp_file")
    
    if [ -n "$file_id" ]; then
        local file_path=$(curl -s "https://api.telegram.org/bot${bot_token}/getFile?file_id=${file_id}" | jq -r '.result.file_path')

        curl -s "https://api.telegram.org/file/bot${bot_token}/${file_path}" -o "$BACKUP_DIR/$file_name"
        rm -f "$temp_file"
        return 0
    fi
    
    rm -f "$temp_file"
    return 1
}

while true; do
    question "Выберите источник восстановления (y - локальный бэкап, n - бэкап из Telegram):"
    case $REPLY in
        [Yy]* ) SOURCE="local"; break;;
        [Nn]* ) SOURCE="telegram"; break;;
        * ) warn "Пожалуйста, ответьте y или n";;
    esac
done

if [ "$SOURCE" = "telegram" ]; then
    question "Введите токен бота:"
    BOT_TOKEN="$REPLY"
    
    question "Введите свой chat_id:"
    CHAT_ID="$REPLY"
    
    info "Получение списка бэкапов из Telegram..."
    mapfile -t TG_BACKUPS < <(get_telegram_backups "$BOT_TOKEN" "$CHAT_ID")
    
    if [ ${#TG_BACKUPS[@]} -eq 0 ]; then
        error "Не найдено бэкапов в Telegram"
        read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1
    fi
    
    echo "Доступные бэкапы в Telegram:"
    for i in "${!TG_BACKUPS[@]}"; do
        echo "$((i+1)). ${TG_BACKUPS[$i]}"
    done
    
    while true; do
        question "Введите номер бэкапа для восстановления:"
        if [[ "$REPLY" =~ ^[0-9]+$ ]] && (( REPLY >= 1 && REPLY <= ${#TG_BACKUPS[@]} )); then
            SELECTED_BACKUP="${TG_BACKUPS[$((REPLY-1))]}"
            info "Выбран архив: $SELECTED_BACKUP"
            break
        else
            warn "Некорректный выбор. Попробуйте снова."
        fi
    done
    
    info "Скачивание бэкапа из Telegram..."
    if ! download_telegram_backup "$BOT_TOKEN" "$CHAT_ID" "$SELECTED_BACKUP"; then
        error "Не удалось скачать бэкап из Telegram"
        read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1
    fi
    success "Бэкап успешно скачан"
else
    mapfile -t ARCHIVES < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'remnawave-backup-*.tar.gz' | sort)
    
    if [[ ${#ARCHIVES[@]} -eq 0 ]]; then
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
    fi
    
    echo "Доступные бэкапы:"
    for i in "${!ARCHIVES[@]}"; do
        echo "$((i+1)). ${ARCHIVES[$i]}"
    done
    
    while true; do
        question "Введите номер бэкапа для восстановления:"
        if [[ "$REPLY" =~ ^[0-9]+$ ]] && (( REPLY >= 1 && REPLY <= ${#ARCHIVES[@]} )); then
            ARCHIVE_PATH="${ARCHIVES[$((REPLY-1))]}"
            info "Выбран архив: $ARCHIVE_PATH"
            break
        else
            warn "Некорректный выбор. Попробуйте снова."
        fi
    done
fi

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
if [ "$SOURCE" = "telegram" ]; then
    cp "$BACKUP_DIR/$SELECTED_BACKUP" "$WORK_DIR/"
    WORK_ARCHIVE="$WORK_DIR/$SELECTED_BACKUP"
else
    cp "$ARCHIVE_PATH" "$WORK_DIR/"
    ARCHIVE_BASENAME=$(basename "$ARCHIVE_PATH")
    WORK_ARCHIVE="$WORK_DIR/$ARCHIVE_BASENAME"
fi
success "Архив скопирован: $WORK_ARCHIVE"

info "Создаю резервную копию текущих данных..."
RESERVE_DB="remnawave-db-backup-before-restore-$DATE.tar.gz"
RESERVE_REDIS="remnawave-redis-backup-before-restore-$DATE.tar.gz"
RESERVE_ARCHIVE="remnawave-backup-before-restore-$DATE.tar.gz"

docker run --rm \
  -v ${DB_VOLUME}:/volume \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czf /backup/$RESERVE_DB -C /volume .
docker run --rm \
  -v ${REDIS_VOLUME}:/volume \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czf /backup/$RESERVE_REDIS -C /volume .
tar czf "$BACKUP_DIR/$RESERVE_ARCHIVE" -C "$BACKUP_DIR" "$RESERVE_DB" "$RESERVE_REDIS"
rm "$BACKUP_DIR/$RESERVE_DB" "$BACKUP_DIR/$RESERVE_REDIS"
success "Резервная копия текущих данных: $BACKUP_DIR/$RESERVE_ARCHIVE"

info "Останавливаю контейнеры Remnawave..."
docker stop $PANEL_CONTAINER $DB_CONTAINER $REDIS_CONTAINER 2>/dev/null
success "Контейнеры остановлены."

info "Распаковка архива в рабочую папку..."
TMP_RESTORE_DIR="$WORK_DIR/unpack"
mkdir -p "$TMP_RESTORE_DIR"
tar xzf "$WORK_ARCHIVE" -C "$TMP_RESTORE_DIR"
success "Архив распакован."

info "Восстанавливаю том $DB_VOLUME..."
docker run --rm \
  -v ${DB_VOLUME}:/volume \
  -v "$TMP_RESTORE_DIR":/backup \
  alpine \
  sh -c "rm -rf /volume/* && tar xzf /backup/remnawave-db-backup-*.tar.gz -C /volume"
success "Том $DB_VOLUME восстановлен."

info "Восстанавливаю том $REDIS_VOLUME..."
docker run --rm \
  -v ${REDIS_VOLUME}:/volume \
  -v "$TMP_RESTORE_DIR":/backup \
  alpine \
  sh -c "rm -rf /volume/* && tar xzf /backup/remnawave-redis-backup-*.tar.gz -C /volume"
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