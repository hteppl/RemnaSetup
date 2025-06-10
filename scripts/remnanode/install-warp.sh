#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"
source "/opt/remnasetup/scripts/common/languages.sh"

check_warp() {
    if ! command -v warp-cli >/dev/null 2>&1; then
        return 0
    fi

    if warp-cli status 2>&1 | grep -q "Status: Connected"; then
        info "$(get_string "install_warp_already_installed")"
        while true; do
            question "$(get_string "install_warp_reconfigure")"
            RECONFIGURE="$REPLY"
            if [[ "$RECONFIGURE" == "y" || "$RECONFIGURE" == "Y" ]]; then
                return 0
            elif [[ "$RECONFIGURE" == "n" || "$RECONFIGURE" == "N" ]]; then
                info "$(get_string "install_warp_already_installed")"
                read -n 1 -s -r -p "$(get_string "install_warp_press_key")"
                exit 0
            else
                warn "$(get_string "install_warp_please_enter_yn")"
            fi
        done
    fi
    return 0
}

install_warp() {
    local WARP_PORT="$1"
    info "$(get_string "install_warp_installing")"

    if ! command -v expect >/dev/null 2>&1; then
        info "$(get_string "install_full_node_installing_expect")"
        sudo apt update -y
        sudo apt install -y expect
    fi

    curl -L https://raw.githubusercontent.com/Skrepysh/tools/refs/heads/main/install-warp-cli.sh > install-warp-cli.sh
    chmod +x install-warp-cli.sh

    if command -v warp-cli >/dev/null 2>&1; then
        expect <<EOF
set timeout 60
spawn ./install-warp-cli.sh
expect "Select action (0-3):"
send "3\r"

expect "Enter WARP-Plus key (leave blank if you don't have a key):"
send "\r"

expect "Enter port for WARP"
send "$WARP_PORT\r"

expect "warp-cli has been configured successfully"
send "\r"
EOF
    else
        expect <<EOF
set timeout 60
spawn ./install-warp-cli.sh
expect "Select action (0-3):"
send "1\r"

expect "Enter WARP-Plus key (leave blank if you don't have a key):"
send "\r"

expect "Enter port for WARP"
send "$WARP_PORT\r"

expect "warp-cli has been configured successfully"
send "\r"
EOF
    fi

    sleep 2
    expect <<EOF
set timeout 60
spawn warp-cli status
expect {
    "Accept Terms of Service and Privacy Policy" {
        send "y\r"
        expect "Status update: Connected"
    }
    "Status update: Connected" {
    }
}
expect eof
EOF

    rm -f install-warp-cli.sh
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
