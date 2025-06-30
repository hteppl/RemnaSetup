#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"
source "/opt/remnasetup/scripts/common/languages.sh"

check_ipv6_status() {
    if sysctl net.ipv6.conf.all.disable_ipv6 | grep -q "= 1"; then
        return 1
    else
        return 0 
    fi
}

display_ipv6_status() {
    if check_ipv6_status; then
        info "$(get_string "ipv6_status_enabled")"
    else
        info "$(get_string "ipv6_status_disabled")"
    fi
}

disable_ipv6() {
    info "$(get_string "ipv6_disabling")"

    sudo tee -a /etc/sysctl.conf > /dev/null << EOF

# IPv6 Disable
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.tun0.disable_ipv6 = 1
EOF

    sudo sysctl -p
    
    success "$(get_string "ipv6_disabled_success")"
}

enable_ipv6() {
    info "$(get_string "ipv6_enabling")"

    sudo sed -i '/^# IPv6 Disable$/,/^net\.ipv6\.conf\.tun0\.disable_ipv6 = 1$/d' /etc/sysctl.conf

    sudo sysctl -p
    
    success "$(get_string "ipv6_enabled_success")"
}

main() {
    clear
    print_header
    menu "$(get_string "ipv6_menu")"
    
    if [ "$LANGUAGE" = "en" ]; then
        echo -e "${BLUE}1. Show IPv6 status${RESET}"
        echo -e "${BLUE}2. Disable IPv6${RESET}"
        echo -e "${BLUE}3. Enable IPv6${RESET}"
        echo -e "${BLUE}4. Back${RESET}"
    else
        echo -e "${BLUE}1. Показать статус IPv6${RESET}"
        echo -e "${BLUE}2. Отключить IPv6${RESET}"
        echo -e "${BLUE}3. Включить IPv6${RESET}"
        echo -e "${BLUE}4. Назад${RESET}"
    fi
    echo
    read -p "$(echo -e "${BOLD_CYAN}$(get_string "select_option"):${RESET}") " IPV6_OPTION
    echo
    
    case $IPV6_OPTION in
        1)
            display_ipv6_status
            read -n 1 -s -r -p "$(get_string "press_any_key")"
            ;;
        2)
            if check_ipv6_status; then
                disable_ipv6
            else
                warn "$(get_string "ipv6_already_disabled")"
            fi
            read -n 1 -s -r -p "$(get_string "press_any_key")"
            ;;
        3)
            if ! check_ipv6_status; then
                enable_ipv6
            else
                warn "$(get_string "ipv6_already_enabled")"
            fi
            read -n 1 -s -r -p "$(get_string "press_any_key")"
            ;;
        4)
            exit 0
            ;;
        *)
            warn "$(get_string "invalid_choice")"
            read -n 1 -s -r -p "$(get_string "press_any_key")"
            ;;
    esac
}

main 