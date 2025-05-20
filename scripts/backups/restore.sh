#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

BACKUP_DIR="/opt/backups"
WORK_DIR="$BACKUP_DIR/restore_work"
DATE=$(date +%F_%H-%M-%S)
DB_VOLUME="remnawave-db-data"
REDIS_VOLUME="remnawave-redis-data"
REMWAVE_DIR="/opt/remnawave"
PANEL_CONTAINER="remnawave"
DB_CONTAINER="remnawave-db"

info "Восстановление Remnawave из бэкапа"

get_telegram_backups() {
    local bot_token=$1
    local chat_id=$2
    local temp_file="/tmp/telegram_backups.json"

    curl -s "https://api.telegram.org/bot${bot_token}/getUpdates?chat_id=${chat_id}&limit=5" > "$temp_file"

    local backups=()
    while IFS= read -r line; do
        if [[ $line =~ remnawave-backup-[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}\.7z ]]; then
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

mkdir -p "$BACKUP_DIR"

if [ "$SOURCE" = "telegram" ]; then
    question "Введите токен бота:"
    BOT_TOKEN="$REPLY"
    
    question "Введите свой chat_id:"
    CHAT_ID="$REPLY"
    
    info "Отправьте архив в бота или ответьте на сообщение с архивом и нажмите любую клавишу для продолжения..."
    read -n 1 -s -r
    
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
    ARCHIVE_PATH="$BACKUP_DIR/$SELECTED_BACKUP"
else
    mapfile -t ARCHIVES < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'remnawave-backup-*.7z' | sort)
    
    if [[ ${#ARCHIVES[@]} -eq 0 ]]; then
        info "Папка $BACKUP_DIR создана. Пожалуйста, положите архив в эту папку и нажмите любую клавишу для продолжения."
        read -n 1 -s -r -p "Нажмите любую клавишу для продолжения..."
        echo
        
        while true; do
            mapfile -t ARCHIVES < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'remnawave-backup-*.7z' | sort)
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

while true; do
    question "Введите пароль от архива (минимум 8 символов):"
    PASSWORD="$REPLY"
    if [ ${#PASSWORD} -ge 8 ]; then
        break
    else
        warn "Пароль должен содержать минимум 8 символов"
    fi
done

if ! command -v docker &>/dev/null; then
    warn "Docker не найден. Пытаюсь установить..."
    sudo curl -fsSL https://get.docker.com | sh
    sudo systemctl start docker
    sudo systemctl enable docker
fi

if [ ! -d "$REMWAVE_DIR" ]; then
    info "Создаю директорию Remnawave..."
    mkdir -p "$REMWAVE_DIR"
fi

info "Проверка архива..."
TMP_RESTORE_DIR="$WORK_DIR/unpack"
mkdir -p "$TMP_RESTORE_DIR"
7z x -p"$PASSWORD" "$ARCHIVE_PATH" -o"$TMP_RESTORE_DIR" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    error "Неверный пароль или поврежденный архив"
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."; exit 1
fi

info "Создаю резервную копию текущих данных..."
RESERVE_ARCHIVE="remnawave-backup-before-restore-$DATE.7z"

if [ -f "$REMWAVE_DIR/.env" ] && [ -f "$REMWAVE_DIR/docker-compose.yml" ]; then
    cp "$REMWAVE_DIR/.env" "$BACKUP_DIR/"
    cp "$REMWAVE_DIR/docker-compose.yml" "$BACKUP_DIR/"
fi

if docker volume inspect $DB_VOLUME &>/dev/null; then
    docker run --rm \
        -v ${DB_VOLUME}:/volume \
        -v "$BACKUP_DIR":/backup \
        alpine \
        tar czf /backup/db_backup.tar.gz -C /volume .
fi

7z a -t7z -m0=lzma2 -mx=9 -mfb=273 -md=64m -ms=on -p"$PASSWORD" "$BACKUP_DIR/$RESERVE_ARCHIVE" "$BACKUP_DIR/db_backup.tar.gz" "$BACKUP_DIR/.env" "$BACKUP_DIR/docker-compose.yml" >/dev/null 2>&1
rm -f "$BACKUP_DIR/db_backup.tar.gz" "$BACKUP_DIR/.env" "$BACKUP_DIR/docker-compose.yml"

if [ "$SOURCE" = "telegram" ]; then
    curl -F "chat_id=$CHAT_ID" \
         -F document=@"$BACKUP_DIR/$RESERVE_ARCHIVE" \
         "https://api.telegram.org/bot$BOT_TOKEN/sendDocument"
fi

success "Резервная копия текущих данных: $BACKUP_DIR/$RESERVE_ARCHIVE"

if [ -d "$REMWAVE_DIR" ]; then
    info "Останавливаю и удаляю контейнеры..."
    cd "$REMWAVE_DIR" && docker compose down
    
    info "Удаляю тома и файлы..."
    docker volume rm $DB_VOLUME $REDIS_VOLUME 2>/dev/null || true
    rm -f "$REMWAVE_DIR/.env" "$REMWAVE_DIR/docker-compose.yml"
fi

info "Восстанавливаю конфигурационные файлы..."
cp "$TMP_RESTORE_DIR/.env" "$REMWAVE_DIR/"
cp "$TMP_RESTORE_DIR/docker-compose.yml" "$REMWAVE_DIR/"

info "Запускаю контейнеры для инициализации БД..."
cd "$REMWAVE_DIR" && docker compose up -d
sleep 10

info "Останавливаю контейнеры..."
docker compose down

info "Очищаю содержимое БД..."
docker run --rm \
    -v ${DB_VOLUME}:/volume \
    alpine \
    sh -c "rm -rf /volume/*"

info "Восстанавливаю базу данных..."
DB_BACKUP_FILE=$(ls "$TMP_RESTORE_DIR"/remnawave-db-backup-*.tar.gz 2>/dev/null | head -n1)
docker run --rm \
    -v ${DB_VOLUME}:/volume \
    -v "$TMP_RESTORE_DIR":/backup \
    alpine \
    tar xzf /backup/$(basename "$DB_BACKUP_FILE") -C /volume

info "Удаляю временные файлы..."
rm -rf "$WORK_DIR"

info "Запускаю контейнеры..."
cd "$REMWAVE_DIR" && docker compose up -d

success "Восстановление завершено!"
read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
exit 0 