#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

check_docker() {
    if command -v docker >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

install_docker() {
    info "Установка Docker..."
    sudo curl -fsSL https://get.docker.com | sh || {
        error "Ошибка: Не удалось установить Docker."
        exit 1
    }
    success "Docker успешно установлен!"
}

check_components() {
    if command -v docker >/dev/null 2>&1; then
        info "Docker уже установлен"
    else
        info "Docker не установлен"
    fi

    if [ -f "/opt/remnanode/docker-compose.yml" ]; then
        info "Remnanode уже установлен"
        while true; do
            question "Хотите скорректировать настройки Remnanode? (y/n):"
            UPDATE_NODE="$REPLY"
            if [[ "$UPDATE_NODE" == "y" || "$UPDATE_NODE" == "Y" ]]; then
                UPDATE_REMNANODE=true
                break
            elif [[ "$UPDATE_NODE" == "n" || "$UPDATE_NODE" == "N" ]]; then
                SKIP_REMNANODE=true
                break
            else
                warn "Пожалуйста, введите только 'y' или 'n'"
            fi
        done
    fi

    if command -v caddy >/dev/null 2>&1; then
        info "Caddy уже установлен"
        while true; do
            question "Хотите скорректировать настройки Caddy? (y/n):"
            UPDATE_CADDY="$REPLY"
            if [[ "$UPDATE_CADDY" == "y" || "$UPDATE_CADDY" == "Y" ]]; then
                UPDATE_CADDY=true
                break
            elif [[ "$UPDATE_CADDY" == "n" || "$UPDATE_CADDY" == "N" ]]; then
                SKIP_CADDY=true
                break
            else
                warn "Пожалуйста, введите только 'y' или 'n'"
            fi
        done
    fi

    if [ -f /opt/tblocker/config.yaml ] && systemctl list-units --full -all | grep -q tblocker.service; then
        info "Tblocker уже установлен"
        while true; do
            question "Хотите скорректировать настройки Tblocker? (y/n):"
            UPDATE_TBLOCKER="$REPLY"
            if [[ "$UPDATE_TBLOCKER" == "y" || "$UPDATE_TBLOCKER" == "Y" ]]; then
                UPDATE_TBLOCKER=true
                break
            elif [[ "$UPDATE_TBLOCKER" == "n" || "$UPDATE_TBLOCKER" == "N" ]]; then
                SKIP_TBLOCKER=true
                break
            else
                warn "Пожалуйста, введите только 'y' или 'n'"
            fi
        done
    fi

    if command -v wireproxy >/dev/null 2>&1; then
        info "WARP уже установлен, пропускаем установку"
        SKIP_WARP=true
    else
        SKIP_WARP=false
    fi

    if sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
        info "BBR уже настроен, пропускаем установку"
        SKIP_BBR=true
    fi
}

request_data() {
    if [[ "$SKIP_CADDY" != "true" ]]; then
        while true; do
            question "Введите доменное имя для self-style (например, noda1.domain.com, n для пропуска):"
            DOMAIN="$REPLY"
            if [[ "$DOMAIN" == "n" || "$DOMAIN" == "N" ]]; then
                while true; do
                    question "Вы точно хотите пропустить установку Caddy? (y/n):"
                    CONFIRM="$REPLY"
                    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                        SKIP_CADDY=true
                        break
                    elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                        break
                    else
                        warn "Пожалуйста, введите только 'y' или 'n'"
                    fi
                done
                if [[ "$SKIP_CADDY" == "true" ]]; then
                    break
                fi
            elif [[ -n "$DOMAIN" ]]; then
                break
            fi
            warn "Доменное имя не может быть пустым. Пожалуйста, введите значение."
        done

        if [[ "$SKIP_CADDY" != "true" ]]; then
            while true; do
                question "Введите порт для self-style (по умолчанию 8443, n для пропуска):"
                MONITOR_PORT="$REPLY"
                if [[ "$MONITOR_PORT" == "n" || "$MONITOR_PORT" == "N" ]]; then
                    while true; do
                        question "Вы точно хотите пропустить установку Caddy? (y/n):"
                        CONFIRM="$REPLY"
                        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                            SKIP_CADDY=true
                            break
                        elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                            break
                        else
                            warn "Пожалуйста, введите только 'y' или 'n'"
                        fi
                    done
                    if [[ "$SKIP_CADDY" == "true" ]]; then
                        break
                    fi
                fi
                MONITOR_PORT=${MONITOR_PORT:-8443}
                if [[ "$MONITOR_PORT" =~ ^[0-9]+$ ]]; then
                    break
                fi
                warn "Порт должен быть числом."
            done
        fi
    fi

    if [[ "$SKIP_REMNANODE" != "true" ]]; then
        while true; do
            question "Введите APP_PORT (по умолчанию 3001, n для пропуска):"
            APP_PORT="$REPLY"
            if [[ "$APP_PORT" == "n" || "$APP_PORT" == "N" ]]; then
                while true; do
                    question "Вы точно хотите пропустить установку Remnanode? (y/n):"
                    CONFIRM="$REPLY"
                    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                        SKIP_REMNANODE=true
                        break
                    elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                        break
                    else
                        warn "Пожалуйста, введите только 'y' или 'n'"
                    fi
                done
                if [[ "$SKIP_REMNANODE" == "true" ]]; then
                    break
                fi
            fi
            APP_PORT=${APP_PORT:-3001}
            if [[ "$APP_PORT" =~ ^[0-9]+$ ]]; then
                break
            fi
            warn "Порт должен быть числом."
        done

        if [[ "$SKIP_REMNANODE" != "true" ]]; then
            while true; do
                question "Введите SSL_CERT (можно получить при добавлении ноды в панели, n для пропуска):"
                SSL_CERT_FULL="$REPLY"
                if [[ "$SSL_CERT_FULL" == "n" || "$SSL_CERT_FULL" == "N" ]]; then
                    while true; do
                        question "Вы точно хотите пропустить установку Remnanode? (y/n):"
                        CONFIRM="$REPLY"
                        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                            SKIP_REMNANODE=true
                            break
                        elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                            break
                        else
                            warn "Пожалуйста, введите только 'y' или 'n'"
                        fi
                    done
                    if [[ "$SKIP_REMNANODE" == "true" ]]; then
                        break
                    fi
                elif [[ -n "$SSL_CERT_FULL" ]]; then
                    break
                fi
                warn "SSL_CERT не может быть пустым. Пожалуйста, введите значение."
            done
        fi
    fi

    if [[ "$SKIP_TBLOCKER" != "true" ]]; then
        while true; do
            question "Введите токен бота для Tblocker (создайте бота в @BotFather для оповещений, n для пропуска):"
            ADMIN_BOT_TOKEN="$REPLY"
            if [[ "$ADMIN_BOT_TOKEN" == "n" || "$ADMIN_BOT_TOKEN" == "N" ]]; then
                while true; do
                    question "Вы точно хотите пропустить установку Tblocker? (y/n):"
                    CONFIRM="$REPLY"
                    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                        SKIP_TBLOCKER=true
                        break
                    elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                        break
                    else
                        warn "Пожалуйста, введите только 'y' или 'n'"
                    fi
                done
                if [[ "$SKIP_TBLOCKER" == "true" ]]; then
                    break
                fi
            elif [[ -n "$ADMIN_BOT_TOKEN" ]]; then
                break
            fi
            warn "Токен бота не может быть пустым. Пожалуйста, введите значение."
        done

        if [[ "$SKIP_TBLOCKER" != "true" ]]; then
            while true; do
                question "Введите Telegram ID админа для Tblocker (n для пропуска):"
                ADMIN_CHAT_ID="$REPLY"
                if [[ "$ADMIN_CHAT_ID" == "n" || "$ADMIN_CHAT_ID" == "N" ]]; then
                    while true; do
                        question "Вы точно хотите пропустить установку Tblocker? (y/n):"
                        CONFIRM="$REPLY"
                        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                            SKIP_TBLOCKER=true
                            break
                        elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                            break
                        else
                            warn "Пожалуйста, введите только 'y' или 'n'"
                        fi
                    done
                    if [[ "$SKIP_TBLOCKER" == "true" ]]; then
                        break
                    fi
                elif [[ -n "$ADMIN_CHAT_ID" ]]; then
                    break
                fi
                warn "Telegram ID админа не может быть пустым. Пожалуйста, введите значение."
            done

            while true; do
                question "Требуется настройка отправки вебхуков? (y/n):"
                WEBHOOK_NEEDED="$REPLY"
                if [[ "$WEBHOOK_NEEDED" == "y" || "$WEBHOOK_NEEDED" == "Y" ]]; then
                    while true; do
                        question "Укажите адрес вебхука (пример portal.domain.com/tblocker/webhook):"
                        WEBHOOK_URL="$REPLY"
                        if [[ -n "$WEBHOOK_URL" ]]; then
                            break
                        fi
                        warn "Адрес вебхука не может быть пустым. Пожалуйста, введите значение."
                    done
                    break
                elif [[ "$WEBHOOK_NEEDED" == "n" || "$WEBHOOK_NEEDED" == "N" ]]; then
                    break
                else
                    warn "Пожалуйста, введите только 'y' или 'n'"
                fi
            done
        fi
    fi

    if [[ "$SKIP_WARP" != "true" ]]; then
        while true; do
            question "Введите порт для WARP (1000-65535, по умолчанию 40000, n для пропуска):"
            WARP_PORT="$REPLY"
            if [[ "$WARP_PORT" == "n" || "$WARP_PORT" == "N" ]]; then
                while true; do
                    question "Вы точно хотите пропустить установку WARP? (y/n):"
                    CONFIRM="$REPLY"
                    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                        SKIP_WARP=true
                        break
                    elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                        break
                    else
                        warn "Пожалуйста, введите только 'y' или 'n'"
                    fi
                done
                if [[ "$SKIP_WARP" == "true" ]]; then
                    break
                fi
            fi
            WARP_PORT=${WARP_PORT:-40000}
            if [[ "$WARP_PORT" =~ ^[0-9]+$ ]] && [ "$WARP_PORT" -ge 1000 ] && [ "$WARP_PORT" -le 65535 ]; then
                break
            fi
            warn "Порт должен быть числом от 1000 до 65535."
        done
    fi

    if [[ "$SKIP_BBR" != "true" ]]; then
        while true; do
            question "Требуется установка BBR? (y/n):"
            BBR_ANSWER="$REPLY"
            if [[ "$BBR_ANSWER" == "n" || "$BBR_ANSWER" == "N" ]]; then
                SKIP_BBR=true
                break
            elif [[ "$BBR_ANSWER" == "y" || "$BBR_ANSWER" == "Y" ]]; then
                SKIP_BBR=false
                break
            else
                warn "Пожалуйста, введите только 'y' или 'n'"
            fi
        done
    fi
}

install_warp() {
    info "Установка WARP (WireProxy)..."
    if ! command -v expect >/dev/null 2>&1; then
        info "Устанавливается пакет expect для автоматизации установки WARP..."
        sudo apt update -y
        sudo apt install -y expect
    fi

    wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh -O menu.sh
    chmod +x menu.sh

    expect <<EOF
spawn bash menu.sh w
expect "Choose:" { send "1\r" }
expect "Choose:" { send "1\r" }
expect "Please customize the Client port" { send "$WARP_PORT\r" }
expect "Choose:" { send "1\r" }
expect eof
EOF
    rm -f menu.sh
    success "WARP успешно установлен!"
}

install_bbr() {
    info "Настройка TCP BBR..."
    sudo sh -c 'modprobe tcp_bbr && sysctl net.ipv4.tcp_available_congestion_control && sysctl -w net.ipv4.tcp_congestion_control=bbr && echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf && sysctl -p'
    success "BBR успешно настроен!"
}

install_caddy() {
    info "Установка Caddy..."
    sudo apt install -y curl debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --yes --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo apt update -y
    sudo apt install -y caddy

    info "Настройка сайта маскировки..."
    sudo chmod -R 777 /var
    sudo mkdir -p /var/www/site
    sudo cp -r "/opt/remnasetup/data/site/"* /var/www/site/

    info "Обновление конфигурации Caddy..."
    sudo cp "/opt/remnasetup/data/caddy/caddyfile-node" /etc/caddy/Caddyfile
    sudo sed -i "s/\$DOMAIN/$DOMAIN/g" /etc/caddy/Caddyfile
    sudo sed -i "s/\$MONITOR_PORT/$MONITOR_PORT/g" /etc/caddy/Caddyfile
    sudo systemctl restart caddy
    success "Caddy успешно установлен!"
}

install_remnanode() {
    info "Установка Remnanode..."
    sudo chmod -R 777 /opt
    mkdir -p /opt/remnanode
    sudo chown $USER:$USER /opt/remnanode
    cd /opt/remnanode

    echo "APP_PORT=$APP_PORT" > .env
    echo "$SSL_CERT_FULL" >> .env

    if [ -f /opt/tblocker/config.yaml ] && systemctl list-units --full -all | grep -q tblocker.service; then
        info "Tblocker уже установлен, используем docker-compose с интеграцией"
        cp "/opt/remnasetup/data/docker/node-tblocker-compose.yml" docker-compose.yml
    elif [[ -n "$ADMIN_BOT_TOKEN" && -n "$ADMIN_CHAT_ID" ]]; then
        info "Данные Tblocker предоставлены, используем docker-compose с интеграцией"
        cp "/opt/remnasetup/data/docker/node-tblocker-compose.yml" docker-compose.yml
    else
        info "Используем стандартный docker-compose"
        cp "/opt/remnasetup/data/docker/node-compose.yml" docker-compose.yml
    fi

    sudo docker compose up -d || {
        error "Ошибка: Не удалось запустить Remnanode. Убедитесь, что Docker настроен корректно."
        exit 1
    }
    success "Remnanode успешно установлен!"
}

install_tblocker() {
    info "Установка Tblocker..."
    sudo mkdir -p /opt/tblocker
    sudo chmod -R 777 /opt/tblocker
    sudo mkdir -p /var/lib/toblock
    sudo chmod -R 777 /var/lib/toblock

    echo "ADMIN_BOT_TOKEN=$ADMIN_BOT_TOKEN" > /tmp/install_vars
    echo "ADMIN_CHAT_ID=$ADMIN_CHAT_ID" >> /tmp/install_vars
    if [[ "$WEBHOOK_NEEDED" == "y" || "$WEBHOOK_NEEDED" == "Y" ]]; then
        echo "WEBHOOK_URL=$WEBHOOK_URL" >> /tmp/install_vars
    fi

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
    
    if [[ "$WEBHOOK_NEEDED" == "y" || "$WEBHOOK_NEEDED" == "Y" ]]; then
        sed -i 's|^SendWebhook:.*$|SendWebhook: true|' /opt/tblocker/config.yaml
        sed -i "s|^WebhookURL:.*$|WebhookURL: \"https://$WEBHOOK_URL\"|" /opt/tblocker/config.yaml
    else
        sed -i 's|^SendWebhook:.*$|SendWebhook: false|' /opt/tblocker/config.yaml
    fi
else
    error "Ошибка: Файл /opt/tblocker/config.yaml не найден."
    exit 1
fi

exit
ROOT_EOF

    info "Настройка crontab..."
    crontab -l > /tmp/crontab_tmp 2>/dev/null || true
    echo "0 * * * * truncate -s 0 /var/lib/toblock/access.log" >> /tmp/crontab_tmp
    echo "0 * * * * truncate -s 0 /var/lib/toblock/error.log" >> /tmp/crontab_tmp
    crontab /tmp/crontab_tmp
    rm /tmp/crontab_tmp

    sudo systemctl restart tblocker.service
    rm -f /tmp/install_vars
    success "Tblocker успешно установлен!"
}

main() {
    info "Начало полной установки Remnanode..."

    check_components
    request_data

    info "Обновление пакетов системы..."
    sudo apt update -y

    if ! check_docker; then
        install_docker
    fi

    if [[ "$SKIP_WARP" != "true" ]]; then
        install_warp
    fi
    
    if [[ "$SKIP_BBR" != "true" ]]; then
        install_bbr
    fi
    
    if [[ "$SKIP_CADDY" != "true" ]]; then
        if [[ "$UPDATE_CADDY" == "true" ]]; then
            sudo systemctl stop caddy
            sudo rm -f /etc/caddy/Caddyfile
        fi
        install_caddy
    fi
    
    if [[ "$SKIP_REMNANODE" != "true" ]]; then
        if [[ "$UPDATE_REMNANODE" == "true" ]]; then
            cd /opt/remnanode
            sudo docker compose down
            rm -f docker-compose.yml
        fi
        install_remnanode
    fi
    
    if [[ "$SKIP_TBLOCKER" != "true" ]]; then
        if [[ "$UPDATE_TBLOCKER" == "true" ]]; then
            sudo systemctl stop tblocker
            sudo rm -f /opt/tblocker/config.yaml
        fi
        install_tblocker
    fi
    
    success "Установка завершена!"
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    exit 0
}

main
