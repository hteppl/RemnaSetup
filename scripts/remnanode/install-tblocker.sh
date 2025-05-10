#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

check_remnanode() {
    if sudo docker ps -q --filter "name=remnanode" | grep -q .; then
        info "Remnanode уже установлен"
        question "Хотите обновить docker-compose файл для интеграции с Tblocker? (y/n): "
        UPDATE_DOCKER="$REPLY"
        
        if [[ "$UPDATE_DOCKER" == "y" || "$UPDATE_DOCKER" == "Y" ]]; then
            return 0
        else
            info "Remnanode уже установлен, docker-compose не будет обновлён"
            return 1
        fi
    fi
    return 0
}

update_docker_compose() {
    info "Обновление docker-compose файла..."
    cd /opt/remnanode
    sudo docker compose down
    rm -f docker-compose.yml
    cp "/opt/remnasetup/data/docker/node-tblocker-compose.yml" docker-compose.yml
    sudo docker compose up -d
    success "Docker-compose файл обновлен!"
}

check_tblocker() {
    if [ -f /opt/tblocker/config.yaml ] && systemctl list-units --full -all | grep -q tblocker.service; then
        info "Tblocker уже установлен"
        question "Желаете обновить конфигурацию? (y/n): "
        UPDATE_CONFIG="$REPLY"
        
        if [[ "$UPDATE_CONFIG" == "y" || "$UPDATE_CONFIG" == "Y" ]]; then
            return 0
        else
            info "Tblocker уже установлен"
            read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
            exit 0
            return 1
        fi
    fi
    return 0
}

setup_crontab() {
    info "Настройка crontab..."
    crontab -l > /tmp/crontab_tmp 2>/dev/null || true
    echo "0 * * * * truncate -s 0 /var/lib/toblock/access.log" >> /tmp/crontab_tmp
    echo "0 * * * * truncate -s 0 /var/lib/toblock/error.log" >> /tmp/crontab_tmp

    crontab /tmp/crontab_tmp
    rm /tmp/crontab_tmp
    success "Crontab настроен!"
}

install_tblocker() {
    info "Установка Tblocker..."
    sudo mkdir -p /opt/tblocker
    sudo chmod -R 777 /opt/tblocker
    sudo mkdir -p /var/lib/toblock
    sudo chmod -R 777 /var/lib/toblock
    sudo su - << 'ROOT_EOF'
source /tmp/install_vars

curl -fsSL git.new/install -o /tmp/tblocker-install.sh || {
    error "Ошибка: Не удалось скачать скрипт Tblocker."
    exit 1
}

printf "\n\n\n" | bash /tmp/tblocker-install.sh || {
    error "Ошибка: Не удалось выполнить скрипт Tblocker."
    exit 1
}

rm /tmp/tblocker-install.sh

if [[ -f /opt/tblocker/config.yaml ]]; then
    sed -i 's|^LogFile:.*$|LogFile: "/var/lib/toblock/access.log"|' /opt/tblocker/config.yaml
    sed -i 's|^UsernameRegex:.*$|UsernameRegex: "email: (\\\\S+)"|' /opt/tblocker/config.yaml
    sed -i "s|^AdminBotToken:.*$|AdminBotToken: \"$ADMIN_BOT_TOKEN\"|" /opt/tblocker/config.yaml
    sed -i "s|^AdminChatID:.*$|AdminChatID: \"$ADMIN_CHAT_ID\"|" /opt/tblocker/config.yaml
else
    error "Ошибка: Файл /opt/tblocker/config.yaml не найден."
    exit 1
fi

exit
ROOT_EOF

    sudo systemctl restart tblocker.service
    success "Tblocker успешно установлен!"
}

update_tblocker_config() {
    info "Обновление конфигурации Tblocker..."
    if [[ -f /opt/tblocker/config.yaml ]]; then
        sudo sed -i 's|^LogFile:.*$|LogFile: "/var/lib/toblock/access.log"|' /opt/tblocker/config.yaml
        sudo sed -i 's|^UsernameRegex:.*$|UsernameRegex: "email: (\\\\S+)"|' /opt/tblocker/config.yaml
        sudo sed -i "s|^AdminBotToken:.*$|AdminBotToken: \"$ADMIN_BOT_TOKEN\"|" /opt/tblocker/config.yaml
        sudo sed -i "s|^AdminChatID:.*$|AdminChatID: \"$ADMIN_CHAT_ID\"|" /opt/tblocker/config.yaml
        sudo systemctl restart tblocker.service
        success "Конфигурация Tblocker обновлена!"
    else
        error "Ошибка: Файл /opt/tblocker/config.yaml не найден."
        exit 1
    fi
}

main() {
    if check_remnanode; then
        update_docker_compose
    fi

    if check_tblocker; then
        while true; do
            question "Введите токен бота для Tblocker (создайте бота в @BotFather для оповещений): "
            ADMIN_BOT_TOKEN="$REPLY"
            if [[ -n "$ADMIN_BOT_TOKEN" ]]; then
                break
            fi
            warn "Токен бота не может быть пустым. Пожалуйста, введите значение."
        done
        echo "ADMIN_BOT_TOKEN=$ADMIN_BOT_TOKEN" > /tmp/install_vars

        while true; do
            question "Введите Telegram ID админа для Tblocker: "
            ADMIN_CHAT_ID="$REPLY"
            if [[ -n "$ADMIN_CHAT_ID" ]]; then
                break
            fi
            warn "Telegram ID админа не может быть пустым. Пожалуйста, введите значение."
        done
        echo "ADMIN_CHAT_ID=$ADMIN_CHAT_ID" >> /tmp/install_vars

        update_tblocker_config
    else
        while true; do
            question "Введите токен бота для Tblocker (создайте бота в @BotFather для оповещений): "
            ADMIN_BOT_TOKEN="$REPLY"
            if [[ -n "$ADMIN_BOT_TOKEN" ]]; then
                break
            fi
            warn "Токен бота не может быть пустым. Пожалуйста, введите значение."
        done
        echo "ADMIN_BOT_TOKEN=$ADMIN_BOT_TOKEN" > /tmp/install_vars

        while true; do
            question "Введите Telegram ID админа для Tblocker: "
            ADMIN_CHAT_ID="$REPLY"
            if [[ -n "$ADMIN_CHAT_ID" ]]; then
                break
            fi
            warn "Telegram ID админа не может быть пустым. Пожалуйста, введите значение."
        done
        echo "ADMIN_CHAT_ID=$ADMIN_CHAT_ID" >> /tmp/install_vars

        install_tblocker
        setup_crontab
    fi

    rm -f /tmp/install_vars
    success "Установка завершена!"
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    exit 0
}

main
