#!/bin/bash

if ! sudo -l &>/dev/null; then
  echo "У пользователя нет прав sudo. Пожалуйста, предоставьте права или запустите от root."
  exit 1
fi

TEMP_VARS_FILE="/tmp/install_vars"
> "$TEMP_VARS_FILE"

display_main_menu() {
  clear
  echo -e "\033[38;5;208m"
  echo -e "┌────────────────────────────────────────────────────────────┐"
  echo -e "│███████╗ ██████╗ ██╗      ██████╗ ██████╗  ██████╗ ████████╗│"
  echo -e "│██╔════╝██╔═══██╗██║     ██╔═══██╗██╔══██╗██╔═══██╗╚══██╔══╝│"
  echo -e "│███████╗██║   ██║██║     ██║   ██║██████╔╝██║   ██║   ██║   │"
  echo -e "│╚════██║██║   ██║██║     ██║   ██║██╔══██╗██║   ██║   ██║   │"
  echo -e "│███████║╚██████╔╝███████╗╚██████╔╝██████╔╝╚██████╔╝   ██║   │"
  echo -e "│╚══════╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝  ╚═════╝    ╚═╝   │"
  echo -e "└────────────────────────────────────────────────────────────┘"
  echo -e "\033[0m"
  echo -e "\033[1;33mGitHub: https://github.com/Vladless/Solo_bot/tree/main\033[0m"
  echo -e "\033[1;33mVersion: v1.2\033[0m"
  echo
  echo -e "\033[1;36m┌────────────────────────┐\033[0m"
  echo -e "\033[1;36m│     Главное меню       │\033[0m"
  echo -e "\033[1;36m└────────────────────────┘\033[0m"
  echo -e "\033[1;34m1. Установка/настройка Remnawave\033[0m"
  echo -e "\033[1;34m2. Установка/настройка Remnanode\033[0m"
  echo -e "\033[1;31m0. Выход\033[0m"
  echo
  read -p "Введите номер опции (0-2): " MAIN_OPTION < /dev/tty
  echo
}

display_remnawave_menu() {
  clear
  echo -e "\033[1;36m┌────────────────────────┐\033[0m"
  echo -e "\033[1;36m│     Меню Remnawave     │\033[0m"
  echo -e "\033[1;36m└────────────────────────┘\033[0m"
  echo -e "\033[1;34m1. Полная установка (Remnawave + Страница подписок + Caddy)\033[0m"
  echo -e "\033[1;34m2. Установка Remnawave\033[0m"
  echo -e "\033[1;34m3. Установка Страницы подписок\033[0m"
  echo -e "\033[1;34m4. Установка Caddy\033[0m"
  echo -e "\033[1;34m5. Обновление (Remnawave + Страницы подписок)\033[0m"
  echo -e "\033[1;34m6. Обновление Remnawave\033[0m"
  echo -e "\033[1;34m7. Обновление Страницы подписок\033[0m"
  echo -e "\033[1;34m8. Назад\033[0m"
  echo
  read -p "Введите номер опции (1-8): " REMNAWAVE_OPTION < /dev/tty
  echo
}

display_remnanode_menu() {
  clear
  echo -e "\033[1;36m┌────────────────────────┐\033[0m"
  echo -e "\033[1;36m│     Меню Remnanode     │\033[0m"
  echo -e "\033[1;36m└────────────────────────┘\033[0m"
  echo -e "\033[1;34m1. Полная установка (Remnanode + Caddy + Tblocker + BBR)\033[0m"
  echo -e "\033[1;34m2. Только Remnanode\033[0m"
  echo -e "\033[1;34m3. Только Caddy + маскировка\033[0m"
  echo -e "\033[1;34m4. Только Tblocker\033[0m"
  echo -e "\033[1;34m5. Только BBR\033[0m"
  echo -e "\033[1;34m6. Обновить Remnanode\033[0m"
  echo -e "\033[1;34m7. Назад\033[0m"
  echo
  read -p "Введите номер опции (1-7): " REMNANODE_OPTION < /dev/tty
  echo
}

check_docker() {
  if command -v docker >/dev/null 2>&1; then
    echo "Docker уже установлен, пропускаем установку."
    return 0
  else
    return 1
  fi
}

check_caddy() {
  if command -v caddy >/dev/null 2>&1 && [ -f /etc/caddy/Caddyfile ]; then
    echo "Caddy уже установлен и настроен, пропускаем установку."
    return 0
  else
    return 1
  fi
}

check_tblocker() {
  if [ -f /opt/tblocker/config.yaml ] && systemctl list-units --full -all | grep -q tblocker.service; then
    echo "Tblocker уже установлен, пропускаем установку."
    return 0
  else
    return 1
  fi
}

check_remnanode() {
  if sudo docker ps -q --filter "name=remnanode" | grep -q .; then
    echo "Remnanode уже настроен и запущен, пропускаем установку."
    return 0
  else
    return 1
  fi
}

check_bbr() {
  if sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
    echo "BBR уже настроен, пропускаем установку."
    return 0
  else
    return 1
  fi
}

check_remnawave() {
  if sudo docker ps -q --filter "name=remnawave" | grep -q .; then
    echo "Remnawave уже настроен и запущен, пропускаем установку."
    return 0
  else
    return 1
  fi
}

check_subscription_page() {
  if sudo docker ps -q --filter "name=remnawave-subscription-page" | grep -q .; then
    echo "Страница подписок уже настроена и запущена, пропускаем установку."
    return 0
  else
    return 1
  fi
}

request_full_wave_data() {
  echo "=== ВАЖНО: Введите данные для настройки Remnawave. Скрипт продолжит выполнение после ввода всех данных ==="
  echo
  
  while true; do
    read -p "Введите домен панели (например, panel.domain.com): " PANEL_DOMAIN < /dev/tty
    if [[ -n "$PANEL_DOMAIN" ]]; then
      break
    fi
    echo "Домен панели не может быть пустым. Пожалуйста, введите значение."
  done
  echo "PANEL_DOMAIN=$PANEL_DOMAIN" >> "$TEMP_VARS_FILE"

  while true; do
    read -p "Введите домен подписок (например, sub.domain.com): " SUB_DOMAIN < /dev/tty
    if [[ -n "$SUB_DOMAIN" ]]; then
      break
    fi
    echo "Домен подписок не может быть пустым. Пожалуйста, введите значение."
  done
  echo "SUB_DOMAIN=$SUB_DOMAIN" >> "$TEMP_VARS_FILE"

  read -p "Введите порт панели (по умолчанию 3000): " PANEL_PORT < /dev/tty
  PANEL_PORT=${PANEL_PORT:-3000}
  echo "PANEL_PORT=$PANEL_PORT" >> "$TEMP_VARS_FILE"

  read -p "Введите порт подписок (по умолчанию 3010): " SUB_PORT < /dev/tty
  SUB_PORT=${SUB_PORT:-3010}
  echo "SUB_PORT=$SUB_PORT" >> "$TEMP_VARS_FILE"

  while true; do
    read -p "Введите логин для метрик: " METRICS_USER < /dev/tty
    if [[ -n "$METRICS_USER" ]]; then
      break
    fi
    echo "Логин для метрик не может быть пустым. Пожалуйста, введите значение."
  done
  echo "METRICS_USER=$METRICS_USER" >> "$TEMP_VARS_FILE"

  while true; do
    read -p "Введите пароль для метрик: " METRICS_PASS < /dev/tty
    if [[ -n "$METRICS_PASS" ]]; then
      break
    fi
    echo "Пароль для метрик не может быть пустым. Пожалуйста, введите значение."
  done
  echo "METRICS_PASS=$METRICS_PASS" >> "$TEMP_VARS_FILE"

  while true; do
    read -p "Введите имя пользователя базы данных: " DB_USER < /dev/tty
    if [[ -n "$DB_USER" ]]; then
      break
    fi
    echo "Имя пользователя базы данных не может быть пустым. Пожалуйста, введите значение."
  done
  echo "DB_USER=$DB_USER" >> "$TEMP_VARS_FILE"

  while true; do
    read -p "Введите пароль пользователя базы данных: " DB_PASS < /dev/tty
    if [[ -n "$DB_PASS" ]]; then
      break
    fi
    echo "Пароль пользователя базы данных не может быть пустым. Пожалуйста, введите значение."
  done
  echo "DB_PASS=$DB_PASS" >> "$TEMP_VARS_FILE"

  while true; do
    read -p "Введите имя проекта: " PROJECT_NAME < /dev/tty
    if [[ -n "$PROJECT_NAME" ]]; then
      break
    fi
    echo "Имя проекта не может быть пустым. Пожалуйста, введите значение."
  done
  echo "PROJECT_NAME=$PROJECT_NAME" >> "$TEMP_VARS_FILE"

  while true; do
    read -p "Введите описание страницы подписки: " SUB_DESCRIPTION < /dev/tty
    if [[ -n "$SUB_DESCRIPTION" ]]; then
      break
    fi
    echo "Описание не может быть пустым. Пожалуйста, введите значение."
  done
  echo "SUB_DESCRIPTION=$SUB_DESCRIPTION" >> "$TEMP_VARS_FILE"

  echo "SUB_PUBLIC_DOMAIN=$SUB_DOMAIN" >> "$TEMP_VARS_FILE"
  JWT_AUTH_SECRET=$(openssl rand -hex 64)
  JWT_API_TOKENS_SECRET=$(openssl rand -hex 64)
  echo "JWT_AUTH_SECRET=$JWT_AUTH_SECRET" >> "$TEMP_VARS_FILE"
  echo "JWT_API_TOKENS_SECRET=$JWT_API_TOKENS_SECRET" >> "$TEMP_VARS_FILE"
}

request_caddy_data() {
  echo "=== ВАЖНО: Введите данные для настройки Caddy. Скрипт продолжит выполнение после ввода всех данных ==="
  echo
  read -p "Введите доменное имя сервера (например, noda1.domain.com): " DOMAIN < /dev/tty
  if [[ -z "$DOMAIN" ]]; then
    echo "Доменное имя не может быть пустым."
    exit 1
  fi
  echo "DOMAIN=$DOMAIN" >> "$TEMP_VARS_FILE"

  read -p "Введите порт маскировки (по умолчанию 8443): " MONITOR_PORT < /dev/tty
  MONITOR_PORT=${MONITOR_PORT:-8443}
  echo "MONITOR_PORT=$MONITOR_PORT" >> "$TEMP_VARS_FILE"
}

request_caddy_wave_data() {
  echo "=== ВАЖНО: Введите данные для настройки Caddy для Remnawave ==="
  echo
  read -p "Введите домен панели (например, panel.domain.com): " PANEL_DOMAIN < /dev/tty
  if [[ -z "$PANEL_DOMAIN" ]]; then
    echo "Домен панели не может быть пустым."
    exit 1
  fi
  echo "PANEL_DOMAIN=$PANEL_DOMAIN" >> "$TEMP_VARS_FILE"

  read -p "Введите домен подписок (например, sub.domain.com): " SUB_DOMAIN < /dev/tty
  if [[ -z "$SUB_DOMAIN" ]]; then
    echo "Домен подписок не может быть пустым."
    exit 1
  fi
  echo "SUB_DOMAIN=$SUB_DOMAIN" >> "$TEMP_VARS_FILE"

  read -p "Введите порт панели (по умолчанию 3000): " PANEL_PORT < /dev/tty
  PANEL_PORT=${PANEL_PORT:-3000}
  echo "PANEL_PORT=$PANEL_PORT" >> "$TEMP_VARS_FILE"

  read -p "Введите порт подписок (по умолчанию 3010): " SUB_PORT < /dev/tty
  SUB_PORT=${SUB_PORT:-3010}
  echo "SUB_PORT=$SUB_PORT" >> "$TEMP_VARS_FILE"
}

request_tblocker_data() {
  echo "=== ВАЖНО: Введите данные для настройки Tblocker. Скрипт продолжит выполнение после ввода всех данных ==="
  echo
  read -p "Введите токен бота для Tblocker (создайте бота в @BotFather для оповещений): " ADMIN_BOT_TOKEN < /dev/tty
  if [[ -z "$ADMIN_BOT_TOKEN" ]]; then
    echo "Токен бота не может быть пустым."
    exit 1
  fi
  echo "ADMIN_BOT_TOKEN=$ADMIN_BOT_TOKEN" >> "$TEMP_VARS_FILE"

  read -p "Введите Telegram ID админа для Tblocker: " ADMIN_CHAT_ID < /dev/tty
  if [[ -z "$ADMIN_CHAT_ID" ]]; then
    echo "Telegram ID админа не может быть пустым."
    exit 1
  fi
  echo "ADMIN_CHAT_ID=$ADMIN_CHAT_ID" >> "$TEMP_VARS_FILE"
}

install_docker() {
  echo "Установка Docker..."
  sudo curl -fsSL https://get.docker.com | sh || {
    echo "Ошибка: Не удалось установить Docker."
    exit 1
  }
}

install_bbr() {
  echo "Настройка TCP BBR..."
  sudo sh -c 'modprobe tcp_bbr && sysctl net.ipv4.tcp_available_congestion_control && sysctl -w net.ipv4.tcp_congestion_control=bbr && echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf && sysctl -p'
}

install_caddy() {
  echo "Установка Caddy..."
  sudo apt install -y curl debian-keyring debian-archive-keyring apt-transport-https
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --yes --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
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
}

install_caddy_wave() {
  echo "Установка Caddy для Remnawave..."
  sudo apt install -y curl debian-keyring debian-archive-keyring apt-transport-https
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
  sudo apt update -y
  sudo apt install -y caddy

  CADDY_CONFIG="/etc/caddy/Caddyfile"
  sudo bash -c "cat > $CADDY_CONFIG <<CADDY_EOF
$PANEL_DOMAIN {
    reverse_proxy 127.0.0.1:$PANEL_PORT {
        header_up X-Real-IP {remote}
        header_up Host {host}
    }
}
$SUB_DOMAIN {
    reverse_proxy 127.0.0.1:$SUB_PORT {
        header_up X-Real-IP {remote}
        header_up Host {host}
    }
}

:443 {
   tls internal
   respond 204
}
CADDY_EOF"

  sudo systemctl restart caddy
}

install_remnanode() {
  echo "Установка Remnanode..."
  sudo chmod -R 777 /opt
  mkdir -p /opt/remnanode
  sudo chown $USER:$USER /opt/remnanode
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

  sudo docker compose up -d || {
    echo "Ошибка: Не удалось запустить Remnanode. Убедитесь, что Docker настроен корректно."
    exit 1
  }
}

install_tblocker() {
  echo "Установка Tblocker..."
  sudo mkdir -p /opt/tblocker
  sudo chmod -R 777 /opt/tblocker
  sudo mkdir -p /var/lib/toblock
  sudo chmod -R 777 /var/lib/toblock
  sudo su - << 'ROOT_EOF'
source /tmp/install_vars

curl -fsSL git.new/install -o /tmp/tblocker-install.sh || {
    echo "Ошибка: Не удалось скачать скрипт Tblocker."
    exit 1
}

printf "\n\n\n" | bash /tmp/tblocker-install.sh || {
    echo "Ошибка: Не удалось выполнить скрипт Tblocker."
    exit 1
}

rm /tmp/tblocker-install.sh

if [[ -f /opt/tblocker/config.yaml ]]; then
    sed -i 's|^LogFile:.*$|LogFile: "/var/lib/toblock/access.log"|' /opt/tblocker/config.yaml
    sed -i 's|^UsernameRegex:.*$|UsernameRegex: "email: (\\S+)"|' /opt/tblocker/config.yaml
    sed -i "s|^AdminBotToken:.*$|AdminBotToken: \"$ADMIN_BOT_TOKEN\"|" /opt/tblocker/config.yaml
    sed -i "s|^AdminChatID:.*$|AdminChatID: \"$ADMIN_CHAT_ID\"|" /opt/tblocker/config.yaml
else
    echo "Ошибка: Файл /opt/tblocker/config.yaml не найден."
    exit 1
fi

exit
ROOT_EOF

  sudo systemctl restart tblocker.service
}

update_remnanode() {
  echo "Обновление Remnanode..."
  if [ ! -d "/opt/remnanode" ]; then
    echo "Ошибка: Директория /opt/remnanode не существует. Установите Remnanode перед обновлением."
    exit 1
  fi
  if ! command -v docker >/dev/null 2>&1; then
    echo "Ошибка: Docker не установлен. Установите Docker перед обновлением Remnanode."
    exit 1
  fi
  cd /opt/remnanode
  sudo docker compose down && sudo docker compose pull && sudo docker compose up -d || {
    echo "Ошибка: Не удалось обновить Remnanode."
    exit 1
  }
}

setup_crontab() {
  echo "Настройка crontab..."
  crontab -l > /tmp/crontab_tmp 2>/dev/null || true
  echo "0 * * * * truncate -s 0 /var/lib/toblock/access.log" >> /tmp/crontab_tmp
  echo "0 * * * * truncate -s 0 /var/lib/toblock/error.log" >> /tmp/crontab_tmp

  crontab /tmp/crontab_tmp
  rm /tmp/crontab_tmp
}

request_subscription_data() {
  echo "=== ВАЖНО: Введите данные для настройки страницы подписок ==="
  echo
  read -p "Введите домен панели (например, panel.domain.com): " PANEL_DOMAIN < /dev/tty
  if [[ -z "$PANEL_DOMAIN" ]]; then
    echo "Домен панели не может быть пустым."
    exit 1
  fi
  echo "PANEL_DOMAIN=$PANEL_DOMAIN" >> "$TEMP_VARS_FILE"

  read -p "Введите порт подписок (по умолчанию 3010): " SUB_PORT < /dev/tty
  SUB_PORT=${SUB_PORT:-3010}
  echo "SUB_PORT=$SUB_PORT" >> "$TEMP_VARS_FILE"

  read -p "Введите имя проекта: " PROJECT_NAME < /dev/tty
  if [[ -z "$PROJECT_NAME" ]]; then
    echo "Имя проекта не может быть пустым."
    exit 1
  fi
  echo "PROJECT_NAME=$PROJECT_NAME" >> "$TEMP_VARS_FILE"

  read -p "Введите описание страницы подписки: " SUB_DESCRIPTION < /dev/tty
  if [[ -z "$SUB_DESCRIPTION" ]]; then
    echo "Описание не может быть пустым."
    exit 1
  fi
  echo "SUB_DESCRIPTION=$SUB_DESCRIPTION" >> "$TEMP_VARS_FILE"
}

install_subscription_page() {
  echo "Установка страницы подписок..."
  sudo chmod -R 777 /opt
  
  mkdir -p /opt/remnawave/subscription && cd /opt/remnawave/subscription
  
  cat > docker-compose.yml <<COMPOSE_EOF
services:
    remnawave-subscription-page:
        image: remnawave/subscription-page:latest
        container_name: remnawave-subscription-page
        hostname: remnawave-subscription-page
        restart: always
        volumes:
            - ./app-config.json:/app/dist/assets/app-config.json
        environment:
            - REMNAWAVE_PLAIN_DOMAIN=$PANEL_DOMAIN
            - SUBSCRIPTION_PAGE_PORT=$SUB_PORT
            - META_TITLE="$PROJECT_NAME"
            - META_DESCRIPTION="$SUB_DESCRIPTION"
        ports:
            - '$SUB_PORT:$SUB_PORT'
        networks:
            - remnawave-network

networks:
    remnawave-network:
        driver: bridge
        external: true
COMPOSE_EOF

  sudo docker compose up -d
  sudo docker compose down
  sudo rm -rf /opt/remnawave/subscription/app-config.json
  curl -sL "https://raw.githubusercontent.com/Capybara-z/RemnaNode/refs/heads/main/files/app-config.json" -o /opt/remnawave/subscription/app-config.json
  sudo docker compose up -d
  
  echo "Установка страницы подписок завершена!"
}

update_remnawave_all() {
  echo "Обновление Remnawave и Страницы подписок..."
  cd /opt/remnawave/subscription
  sudo docker compose down && sudo docker compose pull && sudo docker compose up -d
  
  cd /opt/remnawave
  sudo docker compose down && sudo docker compose pull && sudo docker compose up -d
  
  echo "Обновление завершено!"
}

update_remnawave() {
  echo "Обновление Remnawave..."
  cd /opt/remnawave
  sudo docker compose down && sudo docker compose pull && sudo docker compose up -d
  
  echo "Обновление завершено!"
}

update_subscription_page() {
  echo "Обновление Страницы подписок..."
  cd /opt/remnawave/subscription
  sudo docker compose down && sudo docker compose pull && sudo docker compose up -d
  
  echo "Обновление завершено!"
}

request_remnawave_data() {
  echo "=== ВАЖНО: Введите данные для настройки Remnawave ==="
  echo
  read -p "Введите домен панели (например, panel.domain.com): " PANEL_DOMAIN < /dev/tty
  if [[ -z "$PANEL_DOMAIN" ]]; then
    echo "Домен панели не может быть пустым."
    exit 1
  fi
  echo "PANEL_DOMAIN=$PANEL_DOMAIN" >> "$TEMP_VARS_FILE"

  read -p "Введите порт панели (по умолчанию 3000): " PANEL_PORT < /dev/tty
  PANEL_PORT=${PANEL_PORT:-3000}
  echo "PANEL_PORT=$PANEL_PORT" >> "$TEMP_VARS_FILE"

  read -p "Введите домен подписок (0 для использования домена панели): " SUB_DOMAIN < /dev/tty
  if [[ "$SUB_DOMAIN" == "0" ]]; then
    SUB_PUBLIC_DOMAIN="$PANEL_DOMAIN/api/sub"
  else
    SUB_PUBLIC_DOMAIN="$SUB_DOMAIN"
  fi
  echo "SUB_PUBLIC_DOMAIN=$SUB_PUBLIC_DOMAIN" >> "$TEMP_VARS_FILE"

  read -p "Введите логин для метрик: " METRICS_USER < /dev/tty
  if [[ -z "$METRICS_USER" ]]; then
    echo "Логин для метрик не может быть пустым."
    exit 1
  fi
  echo "METRICS_USER=$METRICS_USER" >> "$TEMP_VARS_FILE"

  read -p "Введите пароль для метрик: " METRICS_PASS < /dev/tty
  if [[ -z "$METRICS_PASS" ]]; then
    echo "Пароль для метрик не может быть пустым."
    exit 1
  fi
  echo "METRICS_PASS=$METRICS_PASS" >> "$TEMP_VARS_FILE"

  read -p "Введите имя пользователя базы данных: " DB_USER < /dev/tty
  if [[ -z "$DB_USER" ]]; then
    echo "Имя пользователя базы данных не может быть пустым."
    exit 1
  fi
  echo "DB_USER=$DB_USER" >> "$TEMP_VARS_FILE"

  read -p "Введите пароль пользователя базы данных: " DB_PASS < /dev/tty
  if [[ -z "$DB_PASS" ]]; then
    echo "Пароль пользователя базы данных не может быть пустым."
    exit 1
  fi
  echo "DB_PASS=$DB_PASS" >> "$TEMP_VARS_FILE"

  JWT_AUTH_SECRET=$(openssl rand -hex 64)
  JWT_API_TOKENS_SECRET=$(openssl rand -hex 64)
  echo "JWT_AUTH_SECRET=$JWT_AUTH_SECRET" >> "$TEMP_VARS_FILE"
  echo "JWT_API_TOKENS_SECRET=$JWT_API_TOKENS_SECRET" >> "$TEMP_VARS_FILE"
}

install_remnawave() {
  echo "Установка Remnawave..."
  sudo apt update -y
  sudo chmod -R 777 /opt && sudo chmod -R 777 /var
  
  mkdir -p /opt/remnawave && cd /opt/remnawave
  
  cat > .env <<ENV_EOF
### APP ###
APP_PORT=$PANEL_PORT
METRICS_PORT=3001

### API ###
API_INSTANCES=1

### DATABASE ###
DATABASE_URL="postgresql://$DB_USER:$DB_PASS@remnawave-db:5432/postgres"

### REDIS ###
REDIS_HOST=remnawave-redis
REDIS_PORT=6379

### JWT ###
JWT_AUTH_SECRET=$JWT_AUTH_SECRET
JWT_API_TOKENS_SECRET=$JWT_API_TOKENS_SECRET

### TELEGRAM ###
IS_TELEGRAM_ENABLED=false
TELEGRAM_BOT_TOKEN=change_me
TELEGRAM_ADMIN_ID=change_me
NODES_NOTIFY_CHAT_ID=change_me

### FRONT_END ###
FRONT_END_DOMAIN=$PANEL_DOMAIN

### SUBSCRIPTION PUBLIC DOMAIN ###
SUB_PUBLIC_DOMAIN=$SUB_PUBLIC_DOMAIN

### SWAGGER ###
SWAGGER_PATH=/docs
SCALAR_PATH=/scalar
IS_DOCS_ENABLED=true

### PROMETHEUS ###
METRICS_USER=$METRICS_USER
METRICS_PASS=$METRICS_PASS

### WEBHOOK ###
WEBHOOK_ENABLED=false
WEBHOOK_URL=https://webhook.site/1234567890
WEBHOOK_SECRET_HEADER=vsmu67Kmg6R8FjIOF1WUY8LWBHie4scdEqrfsKmyf4IAf8dY3nFS0wwYHkhh6ZvQ

### Database ###
POSTGRES_USER=$DB_USER
POSTGRES_PASSWORD=$DB_PASS
POSTGRES_DB=postgres

### HWID DEVICE DETECTION AND LIMITATION ###
HWID_DEVICE_LIMIT_ENABLED=false
ENV_EOF

  cat > docker-compose.yml <<COMPOSE_EOF
services:
   remnawave-db:
       image: postgres:17
       container_name: 'remnawave-db'
       hostname: remnawave-db
       restart: always
       env_file:
           - .env
       environment:
           - POSTGRES_USER=\${POSTGRES_USER}
           - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
           - POSTGRES_DB=\${POSTGRES_DB}
           - TZ=UTC
       ports:
           - '127.0.0.1:6767:5432'
       volumes:
           - remnawave-db-data:/var/lib/postgresql/data
       networks:
           - remnawave-network
       healthcheck:
           test: ['CMD-SHELL', 'pg_isready -U \$\${POSTGRES_USER} -d \$\${POSTGRES_DB}']
           interval: 3s
           timeout: 10s
           retries: 3

   remnawave:
       image: remnawave/backend:latest
       container_name: 'remnawave'
       hostname: remnawave
       restart: always
       ports:
           - '127.0.0.1:$PANEL_PORT:$PANEL_PORT'
       env_file:
           - .env
       networks:
           - remnawave-network
       depends_on:
           remnawave-db:
               condition: service_healthy
           remnawave-redis:
               condition: service_healthy

   remnawave-redis:
       image: valkey/valkey:8.0.2-alpine
       container_name: remnawave-redis
       hostname: remnawave-redis
       restart: always
       networks:
           - remnawave-network
       volumes:
           - remnawave-redis-data:/data
       healthcheck:
           test: ['CMD', 'valkey-cli', 'ping']
           interval: 3s
           timeout: 10s
           retries: 3

networks:
   remnawave-network:
       name: remnawave-network
       driver: bridge
       external: false

volumes:
   remnawave-db-data:
       driver: local
       external: false
       name: remnawave-db-data
   remnawave-redis-data:
       driver: local
       external: false
       name: remnawave-redis-data
COMPOSE_EOF

  sudo docker compose up -d
  
  echo "Установка Remnawave завершена!"
}

install_full_remnawave() {
  echo "Начало полной установки Remnawave..."
  
  request_full_wave_data
  source "$TEMP_VARS_FILE"
  
  echo "Обновление пакетов системы..."
  sudo apt update -y
  
  echo "Установка Caddy..."
  if ! check_caddy; then
    install_caddy_wave
    echo "Caddy успешно установлен!"
  else
    echo "Caddy уже установлен, пропускаем установку."
  fi
  
  echo "Установка Docker..."
  if ! check_docker; then
    install_docker
    echo "Docker успешно установлен!"
  else
    echo "Docker уже установлен, пропускаем установку."
  fi
  
  echo "Установка Remnawave..."
  if ! check_remnawave; then
    install_remnawave
    echo "Remnawave успешно установлен!"
  else
    echo "Remnawave уже установлен, пропускаем установку."
  fi
  
  echo "Установка страницы подписок..."
  if ! check_subscription_page; then
    install_subscription_page
    echo "Страница подписок успешно установлена!"
  else
    echo "Страница подписок уже установлена, пропускаем установку."
  fi
  
  rm /tmp/install_vars
  echo "Полная установка Remnawave завершена!"
}

request_full_data() {
  echo "=== ВАЖНО: Введите данные для настройки Remnanode. Скрипт продолжит выполнение после ввода всех данных ==="
  echo
  while true; do
    read -p "Введите доменное имя сервера (например, noda1.domain.com): " DOMAIN < /dev/tty
    if [[ -n "$DOMAIN" ]]; then
      break
    fi
    echo "Доменное имя не может быть пустым. Пожалуйста, введите значение."
  done
  echo "DOMAIN=$DOMAIN" >> "$TEMP_VARS_FILE"

  read -p "Введите порт маскировки (по умолчанию 8443): " MONITOR_PORT < /dev/tty
  MONITOR_PORT=${MONITOR_PORT:-8443}
  echo "MONITOR_PORT=$MONITOR_PORT" >> "$TEMP_VARS_FILE"

  while true; do
    read -p "Введите APP_PORT (по умолчанию 3001): " APP_PORT < /dev/tty
    APP_PORT=${APP_PORT:-3001}
    if [[ -n "$APP_PORT" ]]; then
      break
    fi
    echo "APP_PORT не может быть пустым. Пожалуйста, введите значение."
  done
  echo "APP_PORT=$APP_PORT" >> "$TEMP_VARS_FILE"

  while true; do
    read -p "Введите SSL_CERT (можно получить при добавлении ноды в панели): " SSL_CERT_FULL < /dev/tty
    if [[ -n "$SSL_CERT_FULL" ]]; then
      break
    fi
    echo "SSL_CERT не может быть пустым. Пожалуйста, введите значение."
  done
  echo "SSL_CERT_FULL=$SSL_CERT_FULL" >> "$TEMP_VARS_FILE"

  while true; do
    read -p "Введите токен бота для Tblocker (создайте бота в @BotFather для оповещений): " ADMIN_BOT_TOKEN < /dev/tty
    if [[ -n "$ADMIN_BOT_TOKEN" ]]; then
      break
    fi
    echo "Токен бота не может быть пустым. Пожалуйста, введите значение."
  done
  echo "ADMIN_BOT_TOKEN=$ADMIN_BOT_TOKEN" >> "$TEMP_VARS_FILE"

  while true; do
    read -p "Введите Telegram ID админа для Tblocker: " ADMIN_CHAT_ID < /dev/tty
    if [[ -n "$ADMIN_CHAT_ID" ]]; then
      break
    fi
    echo "Telegram ID админа не может быть пустым. Пожалуйста, введите значение."
  done
  echo "ADMIN_CHAT_ID=$ADMIN_CHAT_ID" >> "$TEMP_VARS_FILE"
}

while true; do
  display_main_menu
  
  case $MAIN_OPTION in
    1)
      while true; do
        display_remnawave_menu
        
        case $REMNAWAVE_OPTION in
          1)
            install_full_remnawave
            echo "Просмотр логов..."
            cd /opt/remnawave
            sudo docker compose logs -f
            ;;
          2)
            if ! check_remnawave; then
              request_remnawave_data
              sudo apt update -y
              if ! check_docker; then install_docker; fi
              install_remnawave
              echo "Просмотр логов..."
              cd /opt/remnawave
              sudo docker compose logs -f
            fi
            ;;
          3)
            if ! check_subscription_page; then
              request_subscription_data
              sudo apt update -y
              if ! check_docker; then install_docker; fi
              install_subscription_page
              echo "Просмотр логов..."
              cd /opt/remnawave/subscription
              sudo docker compose logs -f
            fi
            ;;
          4)
            if ! check_caddy; then
              request_caddy_wave_data
              sudo apt update -y
              install_caddy_wave
              echo "Caddy успешно установлен!"
            fi
            exit 0
            ;;
          5)
            update_remnawave_all
            echo "Просмотр логов..."
            cd /opt/remnawave
            sudo docker compose logs -f
            ;;
          6)
            update_remnawave
            echo "Просмотр логов..."
            cd /opt/remnawave
            sudo docker compose logs -f
            ;;
          7)
            update_subscription_page
            echo "Просмотр логов..."
            cd /opt/remnawave/subscription
            sudo docker compose logs -f
            ;;
          8)
            break
            ;;
          *)
            echo "Неверный выбор. Попробуйте снова."
            sleep 2
            ;;
        esac
      done
      ;;
      
    2)
      while true; do
        display_remnanode_menu
        
        case $REMNANODE_OPTION in
          1)
            request_full_data
            source "$TEMP_VARS_FILE"
            sudo apt update -y
            if ! check_bbr; then
              install_bbr
            fi
            if ! check_caddy; then
              install_caddy
            fi
            setup_crontab
            if ! check_docker; then install_docker; fi
            if ! check_remnanode; then
              install_remnanode
            fi
            if ! check_tblocker; then
              install_tblocker
            fi
            rm /tmp/install_vars
            echo "Установка завершена!"
            cd /opt/remnanode
            sudo docker compose logs -f
            ;;
          2)
            request_full_data
            source "$TEMP_VARS_FILE"
            sudo apt update -y
            if ! check_docker; then install_docker; fi
            if ! check_remnanode; then
              install_remnanode
            fi
            rm /tmp/install_vars
            echo "Установка завершена!"
            cd /opt/remnanode
            sudo docker compose logs -f
            ;;
          3)
            request_caddy_data
            source "$TEMP_VARS_FILE"
            sudo apt update -y
            if ! check_bbr; then
              install_bbr
            fi
            if ! check_caddy; then
              install_caddy
            fi
            rm /tmp/install_vars
            echo "Установка завершена!"
            exit 0
            ;;
          4)
            request_tblocker_data
            source "$TEMP_VARS_FILE"
            sudo apt update -y
            if ! check_tblocker; then
              install_tblocker
            fi
            setup_crontab
            rm /tmp/install_vars
            echo "Установка завершена!"
            ;;
          5)
            sudo apt update -y
            source "$TEMP_VARS_FILE"
            if ! check_bbr; then
              install_bbr
            fi
            rm /tmp/install_vars
            echo "Установка завершена!"
            ;;
          6)
            update_remnanode
            echo "Обновление завершено!"
            cd /opt/remnanode
            sudo docker compose logs -f
            ;;
          7)
            break
            ;;
          *)
            echo "Неверный выбор. Попробуйте снова."
            sleep 2
            ;;
        esac
      done
      ;;
      
    0)
      echo "Выход из программы..."
      exit 0
      ;;
      
    *)
      echo "Неверный выбор. Попробуйте снова."
      sleep 2
      ;;
  esac
done
