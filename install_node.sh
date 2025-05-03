#!/bin/bash

if ! sudo -l &>/dev/null; then
  echo "У пользователя нет прав sudo. Пожалуйста, предоставьте права или запустите от root."
  exit 1
fi

TEMP_VARS_FILE="/tmp/install_vars"
> "$TEMP_VARS_FILE"

display_menu() {
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
  echo -e "\033[1;33mVersion: v1.1\033[0m"
  echo
  echo -e "\033[1;36m┌────────────────────────┐\033[0m"
  echo -e "\033[1;36m│     Меню установки     │\033[0m"
  echo -e "\033[1;36m└────────────────────────┘\033[0m"
  echo -e "\033[1;34m1. Полная установка (Remnanode + Caddy + Tblocker + BBR)\033[0m"
  echo -e "\033[1;34m2. Только Remnanode\033[0m"
  echo -e "\033[1;34m3. Только Caddy + маскировка\033[0m"
  echo -e "\033[1;34m4. Только Tblocker\033[0m"
  echo -e "\033[1;34m5. Только BBR\033[0m"
  echo -e "\033[1;34m6. Обновить Remnanode\033[0m"
  echo -e "\033[1;31m0. Выход\033[0m"
  echo
  read -p "Введите номер опции (0-6): " OPTION < /dev/tty
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

request_full_data() {
  echo "=== ВАЖНО: Введите данные для настройки. Скрипт продолжит выполнение после ввода всех данных ==="
  echo
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
  if [[ "$MONITOR_PORT" != "7443" && "$MONITOR_PORT" != "8443" ]]; then
    echo "Неверный порт. Будет использован порт 8443 по умолчанию."
    MONITOR_PORT=8443
  fi
  echo "MONITOR_PORT=$MONITOR_PORT" >> "$TEMP_VARS_FILE"
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

install_remnanode() {
  echo "Установка Remnanode..."
  sudo chmod -R 777 /opt
  sudo chmod -R 777 /var
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
  sudo chmod -R 777 /opt
  sudo chmod -R 777 /var
  sudo mkdir -p /var/lib/toblock
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

display_menu

if [[ -z "$OPTION" ]]; then
  echo "Опция не выбрана. Выход из программы."
  exit 1
fi

case $OPTION in
  0)
    echo "Выход из программы."
    exit 0
    ;;
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
  *)
    echo "Неверная опция. Выберите 0, 1, 2, 3, 4, 5 или 6."
    exit 1
    ;;
esac
