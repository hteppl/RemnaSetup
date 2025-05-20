#!/bin/bash

BACKUP_DIR="/opt/backups"
DATE=$(date +%F_%H-%M-%S)
DB_VOLUME="remnawave-db-data"
REMWAVE_DIR="/opt/remnawave"

DB_TAR="remnawave-db-backup-$DATE.tar.gz"
FINAL_ARCHIVE="remnawave-backup-$DATE.7z"

BOT_TOKEN=""
CHAT_ID=""

PASSWORD=""

mkdir -p "$BACKUP_DIR"

docker run --rm \
  -v ${DB_VOLUME}:/volume \
  -v "$BACKUP_DIR":/backup \
  alpine \
  tar czf /backup/$DB_TAR -C /volume .

cp "$REMWAVE_DIR/.env" "$BACKUP_DIR/"
cp "$REMWAVE_DIR/docker-compose.yml" "$BACKUP_DIR/"

7z a -t7z -m0=lzma2 -mx=9 -mfb=273 -md=64m -ms=on -p"$PASSWORD" "$BACKUP_DIR/$FINAL_ARCHIVE" "$BACKUP_DIR/$DB_TAR" "$BACKUP_DIR/.env" "$BACKUP_DIR/docker-compose.yml"

rm "$BACKUP_DIR/$DB_TAR" "$BACKUP_DIR/.env" "$BACKUP_DIR/docker-compose.yml"

curl -F "chat_id=$CHAT_ID" \
     -F document=@"$BACKUP_DIR/$FINAL_ARCHIVE" \
     "https://api.telegram.org/bot$BOT_TOKEN/sendDocument"

find "$BACKUP_DIR" -name "remnawave-backup-*.7z" -type f -mtime +3 -delete

exit 0 