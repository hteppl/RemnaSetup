#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

check_bbr() {
    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
        info "BBR уже настроен"
        read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
        exit 0
        return 1
    fi
    return 0
}

install_bbr() {
    info "Установка BBR..."
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    success "BBR успешно установлен!"
}

main() {
    if ! check_bbr; then
        return 0
    fi

    install_bbr
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    exit 0
}

main
