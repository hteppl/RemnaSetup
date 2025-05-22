#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"
source "/opt/remnasetup/scripts/common/languages.sh"

check_warp() {
    if command -v wireproxy >/dev/null 2>&1; then
        info "$(get_string "install_warp_already_installed")"
        info "$(get_string "install_warp_reinstall_not_possible")"
        read -n 1 -s -r -p "$(get_string "install_warp_press_key")"
        exit 0
    fi
    return 0
}

install_warp() {
    local WARP_PORT="$1"
    info "$(get_string "install_warp_installing")"

    if ! command -v expect >/dev/null 2>&1; then
        info "$(get_string "install_warp_installing_expect")"
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
    success "$(get_string "install_warp_installed_success")"
}

main() {
    if ! check_warp; then
        return 0
    fi

    while true; do
        question "$(get_string "install_warp_enter_port")"
        WARP_PORT="$REPLY"
        WARP_PORT=${WARP_PORT:-40000}
        
        if [[ "$WARP_PORT" =~ ^[0-9]+$ ]] && [ "$WARP_PORT" -ge 1000 ] && [ "$WARP_PORT" -le 65535 ]; then
            break
        fi
        warn "$(get_string "install_warp_port_range")"
    done

    install_warp "$WARP_PORT"
    read -n 1 -s -r -p "$(get_string "install_warp_press_key")"
    exit 0
}

main
