#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

check_warp() {
    if command -v warp-cli >/dev/null 2>&1; then
        info "WARP уже установлен"
        question "Хотите переустановить WARP? (y/n):"
        read -r reinstall
        if [[ "$reinstall" =~ ^[Yy]$ ]]; then
            info "Удаление WARP..."
            systemctl stop warp-svc
            systemctl disable warp-svc
            apt remove -y cloudflare-warp
            apt autoremove -y
            rm -f /etc/apt/sources.list.d/cloudflare-client.list
            rm -f /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
            rm -rf /var/lib/cloudflare-warp
            return 0
        else
            info "Переустановка отменена. Вернитесь в меню."
            read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
            exit 0
        fi
    fi
    return 0
}

check_connection() {
    if warp-cli --accept-tos status | grep -q "Status update: Connected"; then
        return 1
    else
        return 0
    fi
}

check_registration() {
    if warp-cli --accept-tos registration show 2>&1 | grep -q "Error: Missing registration. Try running: \"warp-cli registration new\""; then
        return 1
    else
        return 0
    fi
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
    sleep 10
    for i in {1..30}; do
        if systemctl is-active --quiet warp-svc; then
            break
        fi
        if [ $i -eq 30 ]; then
            error "Сервис WARP не запустился. Попробуйте перезагрузить систему и установить снова."
            exit 1
        fi
        sleep 2
    done

    info "Настройка WARP..."
    
    if check_connection; then
        info "Отключение существующего подключения..."
        warp-cli --accept-tos disconnect
    fi

    if check_registration; then
        info "Регистрация нового клиента..."
        warp-cli --accept-tos registration new
    fi

    info "Настройка режима прокси..."
    warp-cli --accept-tos mode proxy
    
    info "Установка порта $WARP_PORT..."
    warp-cli --accept-tos proxy port $WARP_PORT
    
    info "Подключение к WARP..."
    warp-cli --accept-tos connect

    success "WARP успешно установлен и настроен!"
    info "SOCKS прокси доступен по адресу: 127.0.0.1:$WARP_PORT"
    info "Для проверки работы используйте: curl -x socks5://127.0.0.1:$WARP_PORT ifconfig.me"
    warn "Порт $WARP_PORT не нужно открывать!"
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
            if nc -z 127.0.0.1 "$WARP_PORT" 2>/dev/null; then
                error "Порт $WARP_PORT уже занят. Выберите другой порт."
                continue
            fi
            break
        fi
        warn "Порт должен быть числом от 1000 до 65535."
    done

    install_warp "$WARP_PORT"
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    exit 0
}

main
