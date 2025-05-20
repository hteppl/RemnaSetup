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

get_hours_word() {
    local hours=$1
    local last_digit=$((hours % 10))
    local last_two_digits=$((hours % 100))
    
    if [ $last_two_digits -ge 11 ] && [ $last_two_digits -le 19 ]; then
        echo "часов"
    elif [ $last_digit -eq 1 ]; then
        echo "час"
    elif [ $last_digit -ge 2 ] && [ $last_digit -le 4 ]; then
        echo "часа"
    else
        echo "часов"
    fi
}

get_days_word() {
    local days=$1
    local last_digit=$((days % 10))
    local last_two_digits=$((days % 100))
    
    if [ $last_two_digits -ge 11 ] && [ $last_two_digits -le 19 ]; then
        echo "дней"
    elif [ $last_digit -eq 1 ]; then
        echo "день"
    elif [ $last_digit -ge 2 ] && [ $last_digit -le 4 ]; then
        echo "дня"
    else
        echo "дней"
    fi
} 

cleanup_old_crons() {
    info "Очистка старых задач резервной копии..."
    crontab -l 2>/dev/null | grep -v "$AUTO_BACKUP_DIR/backup.sh" | crontab -
}

while true; do
    question "Выберите режим резервной копии (y - раз в сутки, n - каждые n часов):"
    case $REPLY in
        [Yy]* ) BACKUP_MODE="daily"; break;;
        [Nn]* ) BACKUP_MODE="hourly"; break;;
        * ) warn "Пожалуйста, ответьте y или n";;
    esac
done

if [ "$BACKUP_MODE" = "daily" ]; then
    info "Текущее время сервера: $(date +%H:%M)"
    while true; do
        question "Введите время авто резервной копии (например 23:00):"
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
        question "Введите интервал между резервными копиями в часах (1-23):"
        if [[ "$REPLY" =~ ^[1-9]$|^1[0-9]$|^2[0-3]$ ]]; then
            INTERVAL_HOURS="$REPLY"
            break
        else
            warn "Пожалуйста, введите число от 1 до 23"
        fi
    done
    CRON_SCHEDULE="0 */$INTERVAL_HOURS * * *"
fi

question "Введите максимальное время хранения резервной копии в днях (по умолчанию 3):"
STORAGE_DAYS="$REPLY"
STORAGE_DAYS=${STORAGE_DAYS:-3}

while true; do
    question "Введите пароль для архива (минимум 8 символов):"
    PASSWORD="$REPLY"
    if [ ${#PASSWORD} -ge 8 ]; then
        break
    else
        warn "Пароль должен содержать минимум 8 символов"
    fi
done

while true; do
    question "Хотите отправлять резервную копию в Telegram-бота? (y/n):"
    case $REPLY in
        [Yy]* ) USE_TELEGRAM=true; break;;
        [Nn]* ) USE_TELEGRAM=false; break;;
        * ) warn "Пожалуйста, ответьте y или n";;
    esac
done

if [ "$USE_TELEGRAM" = true ]; then
    question "Введите токен Telegram-бота:"
    BOT_TOKEN="$REPLY"
    
    question "Введите ваш chat_id в Telegram:"
    CHAT_ID="$REPLY"

    cp "$SCRIPT_DIR/backup_script_tg.sh" "$AUTO_BACKUP_DIR/backup.sh"
    sed -i "s/BOT_TOKEN=\"\"/BOT_TOKEN=\"$BOT_TOKEN\"/" "$AUTO_BACKUP_DIR/backup.sh"
    sed -i "s/CHAT_ID=\"\"/CHAT_ID=\"$CHAT_ID\"/" "$AUTO_BACKUP_DIR/backup.sh"
else
    cp "$SCRIPT_DIR/backup_script.sh" "$AUTO_BACKUP_DIR/backup.sh"
fi

sed -i "s/PASSWORD=\"\"/PASSWORD=\"$PASSWORD\"/" "$AUTO_BACKUP_DIR/backup.sh"
sed -i "s/-mtime +3/-mtime +$STORAGE_DAYS/" "$AUTO_BACKUP_DIR/backup.sh"

chmod +x "$AUTO_BACKUP_DIR/backup.sh"

cleanup_old_crons

(crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $AUTO_BACKUP_DIR/backup.sh") | crontab -

success "Авторезервная копия настроена"
if [ "$BACKUP_MODE" = "daily" ]; then
    success "Резервная копия будет выполняться ежедневно в $BACKUP_TIME"
else
    HOURS_WORD=$(get_hours_word "$INTERVAL_HOURS")
    success "Резервная копия будет выполняться каждые $INTERVAL_HOURS $HOURS_WORD"
fi
DAYS_WORD=$(get_days_word "$STORAGE_DAYS")
success "Резервные копии будут храниться $STORAGE_DAYS $DAYS_WORD"
if [ "$USE_TELEGRAM" = true ]; then
    success "Настроена отправка в Telegram-бот"
fi

read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
exit 0