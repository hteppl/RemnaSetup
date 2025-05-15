#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

BACKUP_DIR="/opt/backups"
AUTO_BACKUP_DIR="$BACKUP_DIR/auto_backup"
SCRIPT_DIR="/opt/remnasetup/data/backup"

mkdir -p "$AUTO_BACKUP_DIR"

check_time_format() {
    local time=$1
    if [[ ! $time =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
        return 1
    fi
    return 0
}

cleanup_old_crons() {
    info "Очистка старых задач бэкапа..."
    crontab -l 2>/dev/null | grep -v "$AUTO_BACKUP_DIR/backup.sh" | crontab -
}

while true; do
    question "Выберите режим бэкапа (y - раз в сутки, n - каждые n часов):"
    case $REPLY in
        [Yy]* ) BACKUP_MODE="daily"; break;;
        [Nn]* ) BACKUP_MODE="hourly"; break;;
        * ) warn "Пожалуйста, ответьте y или n";;
    esac
done

if [ "$BACKUP_MODE" = "daily" ]; then
    info "Текущее время сервера: $(date +%H:%M)"
    while true; do
        question "Введите время авто бэкапа (например 23:00):"
        if check_time_format "$REPLY"; then
            BACKUP_TIME="$REPLY"
            break
        else
            warn "Неверный формат времени. Используйте 24-часовой формат (например: 23:00)"
        fi
    done

    HOUR=${BACKUP_TIME%%:*}
    MINUTE=${BACKUP_TIME#*:}
    CRON_SCHEDULE="$MINUTE $HOUR * * *"
else
    while true; do
        question "Введите интервал между бэкапами в часах (1-23):"
        if [[ "$REPLY" =~ ^[1-9]$|^1[0-9]$|^2[0-3]$ ]]; then
            INTERVAL_HOURS="$REPLY"
            break
        else
            warn "Пожалуйста, введите число от 1 до 23"
        fi
    done
    CRON_SCHEDULE="0 */$INTERVAL_HOURS * * *"
fi

question "Введите максимальное время хранения бэкапа в днях (по умолчанию 3):"
STORAGE_DAYS="$REPLY"
STORAGE_DAYS=${STORAGE_DAYS:-3}

while true; do
    question "Хотите отправку бэкапа в телеграм бота? (y/n):"
    case $REPLY in
        [Yy]* ) USE_TELEGRAM=true; break;;
        [Nn]* ) USE_TELEGRAM=false; break;;
        * ) warn "Пожалуйста, ответьте y или n";;
    esac
done

if [ "$USE_TELEGRAM" = true ]; then
    question "Введите токен бота:"
    BOT_TOKEN="$REPLY"
    
    question "Введите свой chat_id:"
    CHAT_ID="$REPLY"

    cp "$SCRIPT_DIR/backup_script_tg.sh" "$AUTO_BACKUP_DIR/backup.sh"
    sed -i "s/BOT_TOKEN=\"\"/BOT_TOKEN=\"$BOT_TOKEN\"/" "$AUTO_BACKUP_DIR/backup.sh"
    sed -i "s/CHAT_ID=\"\"/CHAT_ID=\"$CHAT_ID\"/" "$AUTO_BACKUP_DIR/backup.sh"
else
    cp "$SCRIPT_DIR/backup_script.sh" "$AUTO_BACKUP_DIR/backup.sh"
fi

sed -i "s/-mtime +3/-mtime +$STORAGE_DAYS/" "$AUTO_BACKUP_DIR/backup.sh"

chmod +x "$AUTO_BACKUP_DIR/backup.sh"

cleanup_old_crons

(crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $AUTO_BACKUP_DIR/backup.sh") | crontab -

success "Автобэкап настроен"
if [ "$BACKUP_MODE" = "daily" ]; then
    success "Бэкап будет выполняться ежедневно в $BACKUP_TIME"
else
    success "Бэкап будет выполняться каждые $INTERVAL_HOURS часов"
fi
success "Бэкапы будут храниться $STORAGE_DAYS дней"
if [ "$USE_TELEGRAM" = true ]; then
    success "Настроена отправка в Telegram"
fi

read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
exit 0 