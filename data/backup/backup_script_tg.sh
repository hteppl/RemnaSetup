#!/bin/bash

BACKUP_DIR="/opt/backups"
DATE=$(date +%F_%H-%M-%S)
DB_VOLUME="remnawave-db-data"
REDIS_VOLUME="remnawave-redis-data"

DB_TAR="remnawave-db-backup-$DATE.tar.gz"
REDIS_TAR="remnawave-redis-backup-$DATE.tar.gz"
FINAL_ARCHIVE="remnawave-backup-$DATE.tar.gz"

BOT_TOKEN=""
CHAT_ID=""

mkdir -p "$BACKUP_DIR"

docker run --rm \
  -v ${DB_VOLUME}:/volume \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czf /backup/$DB_TAR -C /volume .

docker run --rm \
  -v ${REDIS_VOLUME}:/volume \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czf /backup/$REDIS_TAR -C /volume .

tar czf "$BACKUP_DIR/$FINAL_ARCHIVE" -C "$BACKUP_DIR" "$DB_TAR" "$REDIS_TAR"

rm "$BACKUP_DIR/$DB_TAR" "$BACKUP_DIR/$REDIS_TAR"

curl -F "chat_id=$CHAT_ID" \
     -F document=@"$BACKUP_DIR/$FINAL_ARCHIVE" \
     "https://api.telegram.org/bot$BOT_TOKEN/sendDocument"

find "$BACKUP_DIR" -name "remnawave-backup-*.tar.gz" -type f -mtime +3 -delete

exit 0 