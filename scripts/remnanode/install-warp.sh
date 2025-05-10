#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

check_warp() {
    if command -v wireproxy >/dev/null 2>&1; then
        info "WARP (WireProxy) уже установлен"
        info "Переустановка невозможна. Вернитесь в меню."
        read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
        exit 0
    fi
    return 0
}

install_warp() {
    local WARP_PORT="$1"
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
