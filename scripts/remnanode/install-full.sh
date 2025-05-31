#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"
source "/opt/remnasetup/scripts/common/languages.sh"

check_docker() {
    if command -v docker >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

install_docker() {
    info "$(get_string "install_full_node_installing_docker")"
    sudo curl -fsSL https://get.docker.com | sh || {
        error "$(get_string "install_full_node_docker_error")"
        exit 1
    }
    success "$(get_string "install_full_node_docker_installed_success")"
}

check_components() {
    if command -v docker >/dev/null 2>&1; then
        info "$(get_string "install_full_node_docker_installed")"
    else
        info "$(get_string "install_full_node_docker_not_installed")"
    fi

    if [ -f "/opt/remnanode/docker-compose.yml" ]; then
        info "$(get_string "install_full_node_remnanode_installed")"
        while true; do
            question "$(get_string "install_full_node_update_remnanode")"
            UPDATE_NODE="$REPLY"
            if [[ "$UPDATE_NODE" == "y" || "$UPDATE_NODE" == "Y" ]]; then
                UPDATE_REMNANODE=true
                break
            elif [[ "$UPDATE_NODE" == "n" || "$UPDATE_NODE" == "N" ]]; then
                SKIP_REMNANODE=true
                break
            else
                warn "$(get_string "install_full_node_please_enter_yn")"
            fi
        done
    fi

    if command -v caddy >/dev/null 2>&1; then
        info "$(get_string "install_full_node_caddy_installed")"
        while true; do
            question "$(get_string "install_full_node_update_caddy")"
            UPDATE_CADDY="$REPLY"
            if [[ "$UPDATE_CADDY" == "y" || "$UPDATE_CADDY" == "Y" ]]; then
                UPDATE_CADDY=true
                break
            elif [[ "$UPDATE_CADDY" == "n" || "$UPDATE_CADDY" == "N" ]]; then
                SKIP_CADDY=true
                break
            else
                warn "$(get_string "install_full_node_please_enter_yn")"
            fi
        done
    fi

    if [ -f /opt/tblocker/config.yaml ] && systemctl list-units --full -all | grep -q tblocker.service; then
        info "$(get_string "install_full_node_tblocker_installed")"
        while true; do
            question "$(get_string "install_full_node_update_tblocker")"
            UPDATE_TBLOCKER="$REPLY"
            if [[ "$UPDATE_TBLOCKER" == "y" || "$UPDATE_TBLOCKER" == "Y" ]]; then
                UPDATE_TBLOCKER=true
                break
            elif [[ "$UPDATE_TBLOCKER" == "n" || "$UPDATE_TBLOCKER" == "N" ]]; then
                SKIP_TBLOCKER=true
                break
            else
                warn "$(get_string "install_full_node_please_enter_yn")"
            fi
        done
    fi

    if command -v warp-cli >/dev/null 2>&1; then
        if warp-cli status 2>&1 | grep -q "Status: Connected"; then
            info "$(get_string "install_full_node_warp_installed")"
            SKIP_WARP=true
        else
            expect <<EOF
spawn warp-cli status
expect "Accept Terms of Service and Privacy Policy?" { send "y\r" }
expect eof
EOF
            info "$(get_string "install_full_node_warp_installed")"
            SKIP_WARP=true
        fi
    else
        SKIP_WARP=false
    fi

    if sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
        info "$(get_string "install_full_node_bbr_configured")"
        SKIP_BBR=true
    fi
}

request_data() {
    if [[ "$SKIP_CADDY" != "true" ]]; then
        while true; do
            question "$(get_string "install_full_node_enter_domain")"
            DOMAIN="$REPLY"
            if [[ "$DOMAIN" == "n" || "$DOMAIN" == "N" ]]; then
                while true; do
                    question "$(get_string "install_full_node_confirm_skip_caddy")"
                    CONFIRM="$REPLY"
                    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                        SKIP_CADDY=true
                        break
                    elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                        break
                    else
                        warn "$(get_string "install_full_node_please_enter_yn")"
                    fi
                done
                if [[ "$SKIP_CADDY" == "true" ]]; then
                    break
                fi
            elif [[ -n "$DOMAIN" ]]; then
                break
            fi
            warn "$(get_string "install_full_node_domain_empty")"
        done

        if [[ "$SKIP_CADDY" != "true" ]]; then
            while true; do
                question "$(get_string "install_full_node_enter_port")"
                MONITOR_PORT="$REPLY"
                if [[ "$MONITOR_PORT" == "n" || "$MONITOR_PORT" == "N" ]]; then
                    while true; do
                        question "$(get_string "install_full_node_confirm_skip_caddy")"
                        CONFIRM="$REPLY"
                        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                            SKIP_CADDY=true
                            break
                        elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                            break
                        else
                            warn "$(get_string "install_full_node_please_enter_yn")"
                        fi
                    done
                    if [[ "$SKIP_CADDY" == "true" ]]; then
                        break
                    fi
                fi
                MONITOR_PORT=${MONITOR_PORT:-8443}
                if [[ "$MONITOR_PORT" =~ ^[0-9]+$ ]]; then
                    break
                fi
                warn "$(get_string "install_full_node_port_must_be_number")"
            done
        fi
    fi

    if [[ "$SKIP_REMNANODE" != "true" ]]; then
        while true; do
            question "$(get_string "install_full_node_enter_app_port")"
            APP_PORT="$REPLY"
            if [[ "$APP_PORT" == "n" || "$APP_PORT" == "N" ]]; then
                while true; do
                    question "$(get_string "install_full_node_confirm_skip_remnanode")"
                    CONFIRM="$REPLY"
                    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                        SKIP_REMNANODE=true
                        break
                    elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                        break
                    else
                        warn "$(get_string "install_full_node_please_enter_yn")"
                    fi
                done
                if [[ "$SKIP_REMNANODE" == "true" ]]; then
                    break
                fi
            fi
            APP_PORT=${APP_PORT:-3001}
            if [[ "$APP_PORT" =~ ^[0-9]+$ ]]; then
                break
            fi
            warn "$(get_string "install_full_node_port_must_be_number")"
        done

        if [[ "$SKIP_REMNANODE" != "true" ]]; then
            while true; do
                question "$(get_string "install_full_node_enter_ssl_cert")"
                SSL_CERT_FULL="$REPLY"
                if [[ "$SSL_CERT_FULL" == "n" || "$SSL_CERT_FULL" == "N" ]]; then
                    while true; do
                        question "$(get_string "install_full_node_confirm_skip_remnanode")"
                        CONFIRM="$REPLY"
                        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                            SKIP_REMNANODE=true
                            break
                        elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                            break
                        else
                            warn "$(get_string "install_full_node_please_enter_yn")"
                        fi
                    done
                    if [[ "$SKIP_REMNANODE" == "true" ]]; then
                        break
                    fi
                elif [[ -n "$SSL_CERT_FULL" ]]; then
                    break
                fi
                warn "$(get_string "install_full_node_ssl_cert_empty")"
            done
        fi
    fi

    if [[ "$SKIP_TBLOCKER" != "true" ]]; then
        while true; do
            question "$(get_string "install_full_node_enter_bot_token")"
            ADMIN_BOT_TOKEN="$REPLY"
            if [[ "$ADMIN_BOT_TOKEN" == "n" || "$ADMIN_BOT_TOKEN" == "N" ]]; then
                while true; do
                    question "$(get_string "install_full_node_confirm_skip_tblocker")"
                    CONFIRM="$REPLY"
                    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                        SKIP_TBLOCKER=true
                        break
                    elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                        break
                    else
                        warn "$(get_string "install_full_node_please_enter_yn")"
                    fi
                done
                if [[ "$SKIP_TBLOCKER" == "true" ]]; then
                    break
                fi
            elif [[ -n "$ADMIN_BOT_TOKEN" ]]; then
                break
            fi
            warn "$(get_string "install_full_node_bot_token_empty")"
        done

        if [[ "$SKIP_TBLOCKER" != "true" ]]; then
            while true; do
                question "$(get_string "install_full_node_enter_chat_id")"
                ADMIN_CHAT_ID="$REPLY"
                if [[ "$ADMIN_CHAT_ID" == "n" || "$ADMIN_CHAT_ID" == "N" ]]; then
                    while true; do
                        question "$(get_string "install_full_node_confirm_skip_tblocker")"
                        CONFIRM="$REPLY"
                        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                            SKIP_TBLOCKER=true
                            break
                        elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                            break
                        else
                            warn "$(get_string "install_full_node_please_enter_yn")"
                        fi
                    done
                    if [[ "$SKIP_TBLOCKER" == "true" ]]; then
                        break
                    fi
                elif [[ -n "$ADMIN_CHAT_ID" ]]; then
                    break
                fi
                warn "$(get_string "install_full_node_chat_id_empty")"
            done

            question "$(get_string "install_full_node_enter_block_duration")"
            BLOCK_DURATION="$REPLY"
            BLOCK_DURATION=${BLOCK_DURATION:-10}

            while true; do
                question "$(get_string "install_full_node_need_webhook")"
                WEBHOOK_NEEDED="$REPLY"
                if [[ "$WEBHOOK_NEEDED" == "y" || "$WEBHOOK_NEEDED" == "Y" ]]; then
                    while true; do
                        question "$(get_string "install_full_node_enter_webhook")"
                        WEBHOOK_URL="$REPLY"
                        if [[ -n "$WEBHOOK_URL" ]]; then
                            break
                        fi
                        warn "$(get_string "install_full_node_webhook_empty")"
                    done
                    break
                elif [[ "$WEBHOOK_NEEDED" == "n" || "$WEBHOOK_NEEDED" == "N" ]]; then
                    break
                else
                    warn "$(get_string "install_full_node_please_enter_yn")"
                fi
            done
        fi
    fi

    if [[ "$SKIP_WARP" != "true" ]]; then
        while true; do
            question "$(get_string "install_full_node_enter_warp_port")"
            WARP_PORT="$REPLY"
            if [[ "$WARP_PORT" == "n" || "$WARP_PORT" == "N" ]]; then
                while true; do
                    question "$(get_string "install_full_node_confirm_skip_warp")"
                    CONFIRM="$REPLY"
                    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
                        SKIP_WARP=true
                        break
                    elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
                        break
                    else
                        warn "$(get_string "install_full_node_please_enter_yn")"
                    fi
                done
                if [[ "$SKIP_WARP" == "true" ]]; then
                    break
                fi
            fi
            WARP_PORT=${WARP_PORT:-40000}
            if [[ "$WARP_PORT" =~ ^[0-9]+$ ]] && [ "$WARP_PORT" -ge 1000 ] && [ "$WARP_PORT" -le 65535 ]; then
                break
            fi
            warn "$(get_string "install_full_node_warp_port_range")"
        done
    fi

    if [[ "$SKIP_BBR" != "true" ]]; then
        while true; do
            question "$(get_string "install_full_node_need_bbr")"
            BBR_ANSWER="$REPLY"
            if [[ "$BBR_ANSWER" == "n" || "$BBR_ANSWER" == "N" ]]; then
                SKIP_BBR=true
                break
            elif [[ "$BBR_ANSWER" == "y" || "$BBR_ANSWER" == "Y" ]]; then
                SKIP_BBR=false
                break
            else
                warn "$(get_string "install_full_node_please_enter_yn")"
            fi
        done
    fi
}

install_warp() {
    info "$(get_string "install_full_node_installing_warp")"
    if ! command -v expect >/dev/null 2>&1; then
        info "$(get_string "install_full_node_installing_expect")"
        sudo apt update -y
        sudo apt install -y expect
    fi

    curl -L https://raw.githubusercontent.com/Skrepysh/tools/refs/heads/main/install-warp-cli.sh > install-warp-cli.sh
    chmod +x install-warp-cli.sh

    expect <<EOF
spawn ./install-warp-cli.sh
expect "Select action (0-3):" { send "1\r" }
expect "Enter WARP-Plus key" { send "\r" }
expect "Enter port for WARP" { send "$WARP_PORT\r" }
expect eof
EOF

    expect <<EOF
spawn warp-cli status
expect "Accept Terms of Service and Privacy Policy?" { send "y\r" }
expect eof
EOF

    rm -f install-warp-cli.sh
    success "$(get_string "install_full_node_warp_installed_success")"
}

install_bbr() {
    info "$(get_string "install_full_node_installing_bbr")"
    sudo sh -c 'modprobe tcp_bbr && sysctl net.ipv4.tcp_available_congestion_control && sysctl -w net.ipv4.tcp_congestion_control=bbr && echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf && sysctl -p'
    success "$(get_string "install_full_node_bbr_installed_success")"
}

install_caddy() {
    info "$(get_string "install_full_node_installing_caddy")"
    sudo apt install -y curl debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --yes --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo apt update -y
    sudo apt install -y caddy

    info "$(get_string "install_full_node_setup_site")"
    sudo chmod -R 777 /var
    sudo mkdir -p /var/www/site
    sudo cp -r "/opt/remnasetup/data/site/"* /var/www/site/

    info "$(get_string "install_full_node_updating_caddy_config")"
    sudo cp "/opt/remnasetup/data/caddy/caddyfile-node" /etc/caddy/Caddyfile
    sudo sed -i "s/\$DOMAIN/$DOMAIN/g" /etc/caddy/Caddyfile
    sudo sed -i "s/\$MONITOR_PORT/$MONITOR_PORT/g" /etc/caddy/Caddyfile
    sudo systemctl restart caddy
    success "$(get_string "install_full_node_caddy_installed_success")"
}

install_remnanode() {
    info "$(get_string "install_full_node_installing_remnanode")"
    sudo chmod -R 777 /opt
    mkdir -p /opt/remnanode
    sudo chown $USER:$USER /opt/remnanode
    cd /opt/remnanode

    echo "APP_PORT=$APP_PORT" > .env
    echo "$SSL_CERT_FULL" >> .env

    if [ -f /opt/tblocker/config.yaml ] && systemctl list-units --full -all | grep -q tblocker.service; then
        info "$(get_string "install_full_node_tblocker_integration")"
        cp "/opt/remnasetup/data/docker/node-tblocker-compose.yml" docker-compose.yml
    elif [[ -n "$ADMIN_BOT_TOKEN" && -n "$ADMIN_CHAT_ID" ]]; then
        info "$(get_string "install_full_node_tblocker_data_provided")"
        cp "/opt/remnasetup/data/docker/node-tblocker-compose.yml" docker-compose.yml
    else
        info "$(get_string "install_full_node_using_standard_compose")"
        cp "/opt/remnasetup/data/docker/node-compose.yml" docker-compose.yml
    fi

    sudo docker compose up -d || {
        error "$(get_string "install_full_node_remnanode_error")"
        exit 1
    }
    success "$(get_string "install_full_node_remnanode_installed_success")"
}

install_tblocker() {
    info "$(get_string "install_full_node_installing_tblocker")"
    sudo mkdir -p /opt/tblocker
    sudo chmod -R 777 /opt/tblocker
    sudo mkdir -p /var/lib/toblock
    sudo chmod -R 777 /var/lib/toblock

    echo "ADMIN_BOT_TOKEN=$ADMIN_BOT_TOKEN" > /tmp/install_vars
    echo "ADMIN_CHAT_ID=$ADMIN_CHAT_ID" >> /tmp/install_vars
    echo "BLOCK_DURATION=$BLOCK_DURATION" >> /tmp/install_vars
    if [[ "$WEBHOOK_NEEDED" == "y" || "$WEBHOOK_NEEDED" == "Y" ]]; then
        echo "WEBHOOK_URL=$WEBHOOK_URL" >> /tmp/install_vars
    fi

    sudo su - << 'ROOT_EOF'
source /tmp/install_vars

curl -fsSL git.new/install -o /tmp/tblocker-install.sh || {
    error "$(get_string "install_full_node_tblocker_download_error")"
    exit 1
}

printf "\n\n\n" | bash /tmp/tblocker-install.sh || {
    error "$(get_string "install_full_node_tblocker_script_error")"
    exit 1
}

rm /tmp/tblocker-install.sh

if [[ -f /opt/tblocker/config.yaml ]]; then
    sed -i 's|^LogFile:.*$|LogFile: "/var/lib/toblock/access.log"|' /opt/tblocker/config.yaml
    sed -i 's|^UsernameRegex:.*$|UsernameRegex: "email: (\\\\S+)"|' /opt/tblocker/config.yaml
    sed -i "s|^AdminBotToken:.*$|AdminBotToken: \"$ADMIN_BOT_TOKEN\"|" /opt/tblocker/config.yaml
    sed -i "s|^AdminChatID:.*$|AdminChatID: \"$ADMIN_CHAT_ID\"|" /opt/tblocker/config.yaml
    sed -i "s|^BlockDuration:.*$|BlockDuration: $BLOCK_DURATION|" /opt/tblocker/config.yaml
    
    if [[ "$WEBHOOK_NEEDED" == "y" || "$WEBHOOK_NEEDED" == "Y" ]]; then
        sed -i 's|^SendWebhook:.*$|SendWebhook: true|' /opt/tblocker/config.yaml
        sed -i "s|^WebhookURL:.*$|WebhookURL: \"https://$WEBHOOK_URL\"|" /opt/tblocker/config.yaml
    else
        sed -i 's|^SendWebhook:.*$|SendWebhook: false|' /opt/tblocker/config.yaml
    fi
else
    error "$(get_string "install_full_node_tblocker_config_error")"
    exit 1
fi

exit
ROOT_EOF

    info "$(get_string "install_full_node_setup_crontab")"
    crontab -l > /tmp/crontab_tmp 2>/dev/null || true
    echo "0 * * * * truncate -s 0 /var/lib/toblock/access.log" >> /tmp/crontab_tmp
    echo "0 * * * * truncate -s 0 /var/lib/toblock/error.log" >> /tmp/crontab_tmp
    crontab /tmp/crontab_tmp
    rm /tmp/crontab_tmp

    sudo systemctl restart tblocker.service
    rm -f /tmp/install_vars
    success "$(get_string "install_full_node_tblocker_installed_success")"
}

main() {
    info "$(get_string "install_full_node_start")"

    check_components
    request_data

    info "$(get_string "install_full_node_updating_packages")"
    sudo apt update -y

    if ! check_docker; then
        install_docker
    fi

    if [[ "$SKIP_WARP" != "true" ]]; then
        install_warp
    fi
    
    if [[ "$SKIP_BBR" != "true" ]]; then
        install_bbr
    fi
    
    if [[ "$SKIP_CADDY" != "true" ]]; then
        if [[ "$UPDATE_CADDY" == "true" ]]; then
            sudo systemctl stop caddy
            sudo rm -f /etc/caddy/Caddyfile
        fi
        install_caddy
    fi
    
    if [[ "$SKIP_REMNANODE" != "true" ]]; then
        if [[ "$UPDATE_REMNANODE" == "true" ]]; then
            cd /opt/remnanode
            sudo docker compose down
            rm -f docker-compose.yml
        fi
        install_remnanode
    fi
    
    if [[ "$SKIP_TBLOCKER" != "true" ]]; then
        if [[ "$UPDATE_TBLOCKER" == "true" ]]; then
            sudo systemctl stop tblocker
            sudo rm -f /opt/tblocker/config.yaml
        fi
        install_tblocker
    fi
    
    success "$(get_string "install_full_node_complete")"
    read -n 1 -s -r -p "$(get_string "install_full_node_press_key")"
    exit 0
}

main
