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

disable_ipv6() {
    info "$(get_string "ipv6_disabling")"
    
    sudo tee -a /etc/sysctl.conf > /dev/null << EOF

# IPv6 Disable
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

    if [ -d "/proc/sys/net/ipv6/conf/tun0" ]; then
        echo "net.ipv6.conf.tun0.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
    fi

    sudo sysctl -p
    
    success "$(get_string "ipv6_disabled_success")"
}

enable_ipv6() {
    info "$(get_string "ipv6_enabling")"

    sudo sed -i '/^# IPv6 Disable$/,/^net\.ipv6\.conf\..*\.disable_ipv6 = 1$/d' /etc/sysctl.conf
    
    sudo sysctl -p
    
    success "$(get_string "ipv6_enabled_success")"
}

main() {
    if check_ipv6_status; then
        echo -e "${GREEN}[INFO] $(get_string "ipv6_status_enabled")${RESET}"
        question "$(get_string "ipv6_disable_confirm")"
        if [[ "$REPLY" == "y" || "$REPLY" == "Y" ]]; then
            disable_ipv6
        else
            info "$(get_string "ipv6_operation_cancelled")"
        fi
    else
        echo -e "${RED}[INFO] $(get_string "ipv6_status_disabled")${RESET}"
        question "$(get_string "ipv6_enable_confirm")"
        if [[ "$REPLY" == "y" || "$REPLY" == "Y" ]]; then
            enable_ipv6
        else
            info "$(get_string "ipv6_operation_cancelled")"
        fi
    fi
    
    read -n 1 -s -r -p "$(get_string "press_any_key")"
    exit 0
}

main 