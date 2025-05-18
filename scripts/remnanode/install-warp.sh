#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

check_warp() {
    if command -v warp-cli >/dev/null 2>&1; then
        info "WARP уже установлен"
        info "Переустановка невозможна. Вернитесь в меню."
        read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
        exit 0
    fi
    return 0
}

install_warp() {
    local WARP_PORT="$1"
    info "Установка WARP..."

    if [ -f /etc/os-release ]; then
        source /etc/os-release
        if [ "$ID" = "debian" ]; then
            NETCAT_PKG="netcat-traditional"
        else
            NETCAT_PKG="netcat-openbsd"
        fi
    fi

    info "Добавление ключа и репозитория Cloudflare WARP..."
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list

    info "Обновление репозиториев..."
    apt update

    info "Установка WARP и необходимых пакетов..."
    apt install -y cloudflare-warp $NETCAT_PKG

    info "Ожидание запуска сервиса WARP..."
    sleep 5
    while ! systemctl is-active --quiet warp-svc; do
        sleep 2
    done

    info "Настройка WARP..."
    warp-cli --accept-tos registration new
    warp-cli --accept-tos mode proxy
    warp-cli --accept-tos proxy port $WARP_PORT
    warp-cli --accept-tos connect

    success "WARP успешно установлен и настроен!"
    info "SOCKS прокси доступен по адресу: 127.0.0.1:$WARP_PORT"
}

main() {
    if ! check_warp; then
        return 0
    fi

    while true; do
        question "Введите порт для WARP (1000-65535, по умолчанию 40000):"
        WARP_PORT="$REPLY"
        WARP_PORT=${WARP_PORT:-40000}
        
        if [[ "$WARP_PORT" =~ ^[0-9]+$ ]] && [ "$WARP_PORT" -ge 1000 ] && [ "$WARP_PORT" -le 65535 ]; then
            break
        fi
        warn "Порт должен быть числом от 1000 до 65535."
    done

    install_warp "$WARP_PORT"
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    exit 0
}

main
