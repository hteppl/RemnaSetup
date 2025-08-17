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

    if command -v warp-cli >/dev/null 2>&1; then
        WARP_STATUS=$(warp-cli status 2>&1)
        if echo "$WARP_STATUS" | grep -q "Status update:"; then
            info "$(get_string "install_full_node_warp_installed")"
            while true; do
                question "$(get_string "install_full_node_update_warp")"
                RECONFIGURE="$REPLY"
                if [[ "$RECONFIGURE" == "y" || "$RECONFIGURE" == "Y" ]]; then
                    SKIP_WARP=false
                    break
                elif [[ "$RECONFIGURE" == "n" || "$RECONFIGURE" == "N" ]]; then
                    SKIP_WARP=true
                    info "$(get_string "install_full_node_warp_skip")"
                    break
                else
                    warn "$(get_string "install_full_node_please_enter_yn")"
                fi
            done
        else
            SKIP_WARP=false
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
EOF
    fi

    sleep 5
    expect <<EOF
set timeout 10
spawn warp-cli status
expect {
    "Accept Terms of Service and Privacy Policy" {
        send "y\r"
    }
    "Status update:" {
    }
}
EOF

    info "$(get_string "install_full_node_adding_warp_crontab")"
    if ! crontab -l 2>/dev/null | grep -q "systemctl restart warp-svc.service"; then
        (crontab -l 2>/dev/null; echo "0 */4 * * * sudo systemctl restart warp-svc.service") | crontab -
        success "$(get_string "install_full_node_warp_crontab_added")"
    else
        info "$(get_string "install_full_node_warp_crontab_already_exists")"
    fi

    rm -f install-warp-cli.sh
    success "$(get_string "install_full_node_warp_installed_success")"
}

install_bbr() {
    info "$(get_string "install_full_node_installing_bbr")"
    sudo sh -c 'modprobe tcp_bbr && sysctl net.ipv4.tcp_available_congestion_control && sysctl -w net.ipv4.tcp_congestion_control=bbr && echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf && sysctl -p'
    success "$(get_string "install_full_node_bbr_installed_success")"
}

setup_logs_and_logrotate() {
    info "$(get_string "install_full_node_setup_logs")"

    if [ ! -d "/var/log/remnanode" ]; then
        sudo mkdir -p /var/log/remnanode
        sudo chmod -R 777 /var/log/remnanode
        info "$(get_string "install_full_node_logs_dir_created")"
    else
        info "$(get_string "install_full_node_logs_dir_exists")"
    fi

    if ! command -v logrotate >/dev/null 2>&1; then
        sudo apt update -y && sudo apt install logrotate -y
    fi

    if [ ! -f "/etc/logrotate.d/remnanode" ] || ! grep -q "copytruncate" /etc/logrotate.d/remnanode; then
        sudo tee /etc/logrotate.d/remnanode > /dev/null <<EOF
/var/log/remnanode/*.log {
    size 50M
    rotate 5
    compress
    missingok
    notifempty
    copytruncate
}
EOF
        success "$(get_string "install_full_node_logs_configured")"
    else
        info "$(get_string "install_full_node_logs_already_configured")"
    fi
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

    if [ -d "/var/www/site" ]; then
        sudo rm -rf /var/www/site/*
    else
        sudo mkdir -p /var/www/site
    fi

    RANDOM_META_ID=$(openssl rand -hex 16)
    RANDOM_CLASS=$(openssl rand -hex 8)
    RANDOM_COMMENT=$(openssl rand -hex 12)

    META_NAMES=("render-id" "view-id" "page-id" "config-id")
    RANDOM_META_NAME=${META_NAMES[$RANDOM % ${#META_NAMES[@]}]}
    
    sudo cp -r "/opt/remnasetup/data/site/"* /var/www/site/

    sudo sed -i "/<meta name=\"viewport\"/a \    <meta name=\"$RANDOM_META_NAME\" content=\"$RANDOM_META_ID\">\n    <!-- $RANDOM_COMMENT -->" /var/www/site/index.html
    sudo sed -i "s/<body/<body class=\"$RANDOM_CLASS\"/" /var/www/site/index.html

    sudo sed -i "1i /* $RANDOM_COMMENT */" /var/www/site/assets/style.css
    sudo sed -i "1i // $RANDOM_COMMENT" /var/www/site/assets/main.js

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

    info "$(get_string "install_full_node_using_standard_compose")"
    cp "/opt/remnasetup/data/docker/node-compose.yml" docker-compose.yml

    sudo docker compose up -d || {
        error "$(get_string "install_full_node_remnanode_error")"
        exit 1
    }
    success "$(get_string "install_full_node_remnanode_installed_success")"
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

    setup_logs_and_logrotate
    
    if [[ "$SKIP_REMNANODE" != "true" ]]; then
        if [[ "$UPDATE_REMNANODE" == "true" ]]; then
            cd /opt/remnanode
            sudo docker compose down
            rm -f docker-compose.yml
        fi
        install_remnanode
    fi
    
    success "$(get_string "install_full_node_complete")"
    read -n 1 -s -r -p "$(get_string "install_full_node_press_key")"
    exit 0
}

main
