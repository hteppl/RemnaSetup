#!/bin/bash

BACKUP_DIR="/opt/backups"
DATE=$(date +%F_%H-%M-%S)
DB_VOLUME="remnawave-db-data"
REMWAVE_DIR="/opt/remnawave"
DB_TAR="remnawave-db-backup-$DATE.tar.gz"
FINAL_ARCHIVE="remnawave-backup-$DATE.7z"
TMP_DIR="$BACKUP_DIR/tmp-$DATE"

BOT_TOKEN=""
CHAT_ID=""
PASSWORD=""
LANGUAGE=""

START_TIME=$(date +%s)

mkdir -p "$BACKUP_DIR"
mkdir -p "$TMP_DIR"

if docker volume inspect $DB_VOLUME &>/dev/null; then
  docker run --rm \
    -v ${DB_VOLUME}:/volume \
    -v "$TMP_DIR":/backup \
    alpine \
    tar czf /backup/$DB_TAR -C /volume .
fi

cp "$REMWAVE_DIR/.env" "$TMP_DIR/"
cp "$REMWAVE_DIR/docker-compose.yml" "$TMP_DIR/"

7z a -t7z -m0=lzma2 -mx=9 -mfb=273 -md=64m -ms=on -p"$PASSWORD" "$BACKUP_DIR/$FINAL_ARCHIVE" "$TMP_DIR/*" >/dev/null 2>&1

rm -rf "$TMP_DIR"

find "$BACKUP_DIR" -maxdepth 1 -type f -name 'remnawave-backup-*.7z' -mtime +3 -delete

END_TIME=$(date +%s)
DURATION_SEC=$((END_TIME - START_TIME))
DURATION=$(date -u -d @${DURATION_SEC} +%H:%M:%S)
ARCHIVE_SIZE=$(du -h "$BACKUP_DIR/$FINAL_ARCHIVE" | awk '{print $1}')
FREE_SPACE=$(df -h "$BACKUP_DIR" | awk 'NR==2{print $4}')

if [ "$LANGUAGE" = "en" ]; then
    MSG=$(cat <<EOF
#Remnawave
✅ Remnawave backup successfully created!

🗓️ Date: $DATE

⌛️ Duration: $DURATION
💾 Archive size: $ARCHIVE_SIZE

📦 Archive contents:
- DB: $DB_VOLUME
- Configs: .env, docker-compose.yml

🗄️ Free space: $FREE_SPACE
EOF
)
else
    MSG=$(cat <<EOF
#Remnawave
✅ Резервная копия Remnawave успешно создана!

🗓️ Дата: $DATE

⌛️ Время выполнения: $DURATION
💾 Размер архива: $ARCHIVE_SIZE

📦 Состав архива:
- БД: $DB_VOLUME
- Конфиги: .env, docker-compose.yml

🗄️ Свободное место: $FREE_SPACE
EOF
)
fi

if [ -n "$BOT_TOKEN" ] && [ -n "$CHAT_ID" ]; then
  curl -F "chat_id=$CHAT_ID" -F "caption=$MSG" -F document=@"$BACKUP_DIR/$FINAL_ARCHIVE" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument"
fi

exit 0 