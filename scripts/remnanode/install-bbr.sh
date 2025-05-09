#!/bin/bash

source "$(dirname "$0")/../../scripts/common/colors.sh"
source "$(dirname "$0")/../../scripts/common/functions.sh"

check_bbr() {
    if sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
        info "BBR уже настроен"
        read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
        "$(dirname "$0")/../../scripts/remnanode/menu.sh"
        exit 0
    fi
}

install_bbr() {
    info "Настройка TCP BBR..."
    sudo sh -c 'modprobe tcp_bbr && sysctl net.ipv4.tcp_available_congestion_control && sysctl -w net.ipv4.tcp_congestion_control=bbr && echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf && sysctl -p'
    success "BBR успешно настроен!"
}

main() {
    check_bbr
    install_bbr

    success "Установка завершена!"
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    "$(dirname "$0")/../../scripts/remnanode/menu.sh"
}

main
