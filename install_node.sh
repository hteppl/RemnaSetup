#!/bin/bash

if ! sudo -l &>/dev/null; then
  echo "У пользователя нет прав sudo. Пожалуйста, предоставьте права или запустите от root."
  exit 1
fi

TEMP_VARS_FILE="/tmp/install_vars"
> "$TEMP_VARS_FILE"

echo "=== ВАЖНО: Введите данные для настройки. Скрипт продолжит выполнение после ввода всех данных ==="

read -p "Введите доменное имя сервера (например, noda1.domain.com): " DOMAIN < /dev/tty
if [[ -z "$DOMAIN" ]]; then
    echo "Доменное имя не может быть пустым."
    exit 1
fi
echo "DOMAIN=$DOMAIN" >> "$TEMP_VARS_FILE"

read -p "Введите порт маскировки (по умолчанию 8443): " MONITOR_PORT < /dev/tty
if [[ "$MONITOR_PORT" != "7443" && "$MONITOR_PORT" != "8443" ]]; then
    echo "Неверный порт. Будет использован порт 8443 по умолчанию."
    MONITOR_PORT=8443
fi
echo "MONITOR_PORT=$MONITOR_PORT" >> "$TEMP_VARS_FILE"

read -p "Введите APP_PORT (по умолчанию 3001): " APP_PORT < /dev/tty
APP_PORT=${APP_PORT:-3001}
echo "APP_PORT=$APP_PORT" >> "$TEMP_VARS_FILE"

read -p "Введите SSL_CERT (можно получить при добавлении ноды в панели): " SSL_CERT_FULL < /dev/tty
if [[ -z "$SSL_CERT_FULL" ]]; then
    echo "SSL_CERT не может быть пустым."
    exit 1
fi
echo "SSL_CERT_FULL=$SSL_CERT_FULL" >> "$TEMP_VARS_FILE"

read -p "Введите токен бота для tblocker: " ADMIN_BOT_TOKEN < /dev/tty
if [[ -z "$ADMIN_BOT_TOKEN" ]]; then
    echo "Токен бота не может быть пустым."
    exit 1
fi
echo "ADMIN_BOT_TOKEN=$ADMIN_BOT_TOKEN" >> "$TEMP_VARS_FILE"

read -p "Введите Telegram ID админа для tblocker: " ADMIN_CHAT_ID < /dev/tty
if [[ -z "$ADMIN_CHAT_ID" ]]; then
    echo "Telegram ID админа не может быть пустым."
    exit 1
fi
echo "ADMIN_CHAT_ID=$ADMIN_CHAT_ID" >> "$TEMP_VARS_FILE"

echo "=== Все данные введены, начинаем установку ==="

source "$TEMP_VARS_FILE"

sudo apt update -y
sudo apt install -y ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo apt install -y docker-compose-plugin

sudo usermod -aG docker "$USER"

newgrp docker << 'DOCKER_EOF'
source /tmp/install_vars

sudo sh -c 'modprobe tcp_bbr && sysctl net.ipv4.tcp_available_congestion_control && sysctl -w net.ipv4.tcp_congestion_control=bbr && echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf && sysctl -p'

sudo apt install -y curl debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update -y
sudo apt install -y caddy

CADDY_CONFIG="/etc/caddy/Caddyfile"
sudo bash -c "cat > \"$CADDY_CONFIG\" <<CADDY_EOF
$DOMAIN:$MONITOR_PORT {
    @local {
        remote_ip 127.0.0.1 ::1
    }

    handle @local {
        root * /var/www/site
        try_files {path} /index.html
        file_server
    }

    handle {
        abort
    }
}
CADDY_EOF"

sudo chmod -R 777 /opt
sudo chmod -R 777 /var

mkdir -p /var/www/site
mkdir -p /var/www/site/assets

curl -sL "https://raw.githubusercontent.com/Capybara-z/remnanode/refs/heads/main/files/index.html" -o /var/www/site/index.html
curl -sL "https://raw.githubusercontent.com/Capybara-z/remnanode/refs/heads/main/files/assets/main.js" -o /var/www/site/assets/main.js
curl -sL "https://raw.githubusercontent.com/Capybara-z/remnanode/refs/heads/main/files/assets/style.css" -o /var/www/site/assets/style.css

sudo systemctl reload caddy

mkdir -p /opt/remnanode
cd /opt/remnanode

echo "APP_PORT=$APP_PORT" > .env
echo "$SSL_CERT_FULL" >> .env

cat > docker-compose.yml <<COMPOSE_EOF
services:
    remnanode:
        container_name: remnanode
        hostname: remnanode
        image: remnawave/node:latest
        restart: always
        network_mode: host
        env_file:
            - .env
        volumes:
            - /var/lib/toblock:/var/lib/toblock
COMPOSE_EOF

sudo mkdir -p /var/lib/toblock
sudo su - << 'ROOT_EOF'

source /tmp/install_vars

curl -fsSL git.new/install -o /tmp/tblocker-install.sh || {
    echo "Ошибка: Не удалось скачать скрипт tblocker."
    exit 1
}

sudo bash /tmp/tblocker-install.sh || {
    echo "Ошибка: Не удалось выполнить скрипт tblocker."
    exit 1
}

rm /tmp/tblocker-install.sh

if [[ -f /opt/tblocker/config.yaml ]]; then

    sed -i 's|LogFile:.*|LogFile: "/var/lib/toblock/access.log"|' /opt/tblocker/config.yaml
    sed -i 's|UsernameRegex:.*|UsernameRegex: "email: (\\S+)"|' /opt/tblocker/config.yaml
    sed -i "s|AdminBotToken: \".*\"|AdminBotToken: \"$ADMIN_BOT_TOKEN\"|" /opt/tblocker/config.yaml
    sed -i "s|AdminChatID: \".*\"|AdminChatID: \"$ADMIN_CHAT_ID\"|" /opt/tblocker/config.yaml
else
    echo "Ошибка: Файл /opt/tblocker/config.yaml не найден."
    exit 1
fi

if systemctl list-units --full -all | grep -q tblocker.service; then
    systemctl restart tblocker.service
else
    echo "Ошибка: Сервис tblocker.service не найден."
    exit 1
fi
exit
ROOT_EOF

crontab -l > /tmp/crontab_tmp 2>/dev/null || true

echo "0 * * * * truncate -s 0 /var/lib/toblock/access.log" >> /tmp/crontab_tmp
echo "0 * * * * truncate -s 0 /var/lib/toblock/error.log" >> /tmp/crontab_tmp

EDITOR=nano crontab -e << 'CRON_EOF'
/tmp/crontab_tmp
CRON_EOF

rm /tmp/crontab_tmp

cd /opt/remnanode
docker compose up -d
docker compose logs -f

rm /tmp/install_vars
DOCKER_EOF
