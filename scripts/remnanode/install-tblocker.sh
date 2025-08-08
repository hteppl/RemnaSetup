#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"
source "/opt/remnasetup/scripts/common/languages.sh"

check_remnanode() {
    if ! command -v docker >/dev/null 2>&1; then
        return 0
    fi

    if [ ! -d "/opt/remnanode" ]; then
        return 0
    fi

    if sudo docker ps -q --filter "name=remnanode" | grep -q .; then
        info "$(get_string "install_tblocker_remnanode_installed")"
        while true; do
            question "$(get_string "install_tblocker_update_docker")"
            UPDATE_DOCKER="$REPLY"
            if [[ "$UPDATE_DOCKER" == "y" || "$UPDATE_DOCKER" == "Y" ]]; then
                return 0
            elif [[ "$UPDATE_DOCKER" == "n" || "$UPDATE_DOCKER" == "N" ]]; then
                info "$(get_string "install_tblocker_remnanode_installed")"
                return 1
            else
                warn "$(get_string "install_tblocker_please_enter_yn")"
            fi
        done
    fi
    return 0
}

update_docker_compose() {
    if ! command -v docker >/dev/null 2>&1; then
        return 0
    fi

    if [ ! -d "/opt/remnanode" ]; then
        return 0
    fi

    info "$(get_string "install_tblocker_update_compose")"
    cd /opt/remnanode

    if [ -f "docker-compose.yml" ]; then
        sudo docker compose down

        if ! grep -q "/var/log/remnanode:/var/log/remnanode" docker-compose.yml; then
            if grep -q "volumes:" docker-compose.yml; then
                sudo sed -i '/volumes:/a\            - /var/log/remnanode:/var/log/remnanode' docker-compose.yml
            else
                sudo sed -i '/env_file:/a\        volumes:\n            - /var/log/remnanode:/var/log/remnanode' docker-compose.yml
            fi
            sudo docker compose up -d
            success "$(get_string "install_tblocker_compose_updated")"
        else
            sudo docker compose up -d
            info "$(get_string "install_tblocker_volume_already_exists")"
        fi
    else
        info "$(get_string "install_tblocker_no_compose_file")"
        return 0
    fi
}

check_tblocker() {
    if [ -f /opt/tblocker/config.yaml ] && systemctl list-units --full -all | grep -q tblocker.service; then
        info "$(get_string "install_tblocker_already_installed")"
        while true; do
            question "$(get_string "install_tblocker_update_config")"
            UPDATE_CONFIG="$REPLY"
            if [[ "$UPDATE_CONFIG" == "y" || "$UPDATE_CONFIG" == "Y" ]]; then
                return 0
            elif [[ "$UPDATE_CONFIG" == "n" || "$UPDATE_CONFIG" == "N" ]]; then
                info "$(get_string "install_tblocker_already_installed")"
                read -n 1 -s -r -p "$(get_string "install_tblocker_press_key")"
                exit 0
            else
                warn "$(get_string "install_tblocker_please_enter_yn")"
            fi
        done
    fi
    return 1
}

check_webhook() {
    while true; do
        question "$(get_string "install_tblocker_need_webhook")"
        WEBHOOK_NEEDED="$REPLY"
        if [[ "$WEBHOOK_NEEDED" == "y" || "$WEBHOOK_NEEDED" == "Y" ]]; then
            while true; do
                question "$(get_string "install_tblocker_enter_webhook")"
                WEBHOOK_URL="$REPLY"
                if [[ -n "$WEBHOOK_URL" ]]; then
                    break
                fi
                warn "$(get_string "install_tblocker_webhook_empty")"
            done
            return 0
        elif [[ "$WEBHOOK_NEEDED" == "n" || "$WEBHOOK_NEEDED" == "N" ]]; then
            return 1
        else
            warn "$(get_string "install_tblocker_please_enter_yn")"
        fi
    done
}



setup_logs_and_logrotate() {
    info "$(get_string "install_tblocker_setup_logs")"

    if [ ! -d "/var/log/remnanode" ]; then
        sudo mkdir -p /var/log/remnanode
        sudo chmod -R 777 /var/log/remnanode
        info "$(get_string "install_tblocker_logs_dir_created")"
    else
        info "$(get_string "install_tblocker_logs_dir_exists")"
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
        success "$(get_string "install_tblocker_logs_configured")"
    else
        info "$(get_string "install_tblocker_logs_already_configured")"
    fi
}

install_iptables() {
    info "$(get_string "install_tblocker_installing_iptables")"
    sudo apt update -y && sudo apt install iptables -y
    success "$(get_string "install_tblocker_iptables_installed")"
}

install_tblocker() {
    info "$(get_string "install_tblocker_installing")"

    sudo su - << 'ROOT_EOF'
bash <(curl -fsSL git.new/install) << 'INSTALL_INPUT'
/var/log/remnanode/access.log
y
1
INSTALL_INPUT
exit
ROOT_EOF
    
    if [[ -f /opt/tblocker/config.yaml ]]; then
        if grep -q "^UsernameRegex:" /opt/tblocker/config.yaml; then
            sudo sed -i 's|^UsernameRegex:.*$|UsernameRegex: "email: (\\\\S+)"|' /opt/tblocker/config.yaml
        else
            echo 'UsernameRegex: "email: (\\\\S+)"' | sudo tee -a /opt/tblocker/config.yaml
        fi

        if grep -q "^BlockDuration:" /opt/tblocker/config.yaml; then
            sudo sed -i "s|^BlockDuration:.*$|BlockDuration: $BLOCK_DURATION|" /opt/tblocker/config.yaml
        else
            echo "BlockDuration: $BLOCK_DURATION" | sudo tee -a /opt/tblocker/config.yaml
        fi

        if [[ "$WEBHOOK_NEEDED" == "y" || "$WEBHOOK_NEEDED" == "Y" ]]; then
            if grep -q "^SendWebhook:" /opt/tblocker/config.yaml; then
                sudo sed -i 's|^SendWebhook:.*$|SendWebhook: true|' /opt/tblocker/config.yaml
            else
                echo "SendWebhook: true" | sudo tee -a /opt/tblocker/config.yaml
            fi
            
            if grep -q "^WebhookURL:" /opt/tblocker/config.yaml; then
                sudo sed -i "s|^WebhookURL:.*$|WebhookURL: \"https://$WEBHOOK_URL\"|" /opt/tblocker/config.yaml
            else
                echo "WebhookURL: \"https://$WEBHOOK_URL\"" | sudo tee -a /opt/tblocker/config.yaml
            fi

            if ! grep -q "^WebhookTemplate:" /opt/tblocker/config.yaml; then
                echo "WebhookTemplate: '{\"username\":\"%s\",\"ip\":\"%s\",\"server\":\"%s\",\"action\":\"%s\",\"duration\":%d,\"timestamp\":\"%s\"}'" | sudo tee -a /opt/tblocker/config.yaml
            fi

            if ! grep -q "^WebhookHeaders:" /opt/tblocker/config.yaml; then
                echo "WebhookHeaders:" | sudo tee -a /opt/tblocker/config.yaml
                echo "  Content-Type: \"application/json\"" | sudo tee -a /opt/tblocker/config.yaml
            fi
        else
            if grep -q "^SendWebhook:" /opt/tblocker/config.yaml; then
                sudo sed -i 's|^SendWebhook:.*$|SendWebhook: false|' /opt/tblocker/config.yaml
            else
                echo "SendWebhook: false" | sudo tee -a /opt/tblocker/config.yaml
            fi
        fi
    else
        error "$(get_string "install_tblocker_config_error")"
        exit 1
    fi

    sudo systemctl restart tblocker.service
    success "$(get_string "install_tblocker_installed_success")"
}

update_tblocker_config() {
    info "$(get_string "install_tblocker_updating_config")"
    if [[ -f /opt/tblocker/config.yaml ]]; then
        if grep -q "^UsernameRegex:" /opt/tblocker/config.yaml; then
            sudo sed -i 's|^UsernameRegex:.*$|UsernameRegex: "email: (\\\\S+)"|' /opt/tblocker/config.yaml
        else
            echo 'UsernameRegex: "email: (\\\\S+)"' | sudo tee -a /opt/tblocker/config.yaml
        fi

        if grep -q "^BlockDuration:" /opt/tblocker/config.yaml; then
            sudo sed -i "s|^BlockDuration:.*$|BlockDuration: $BLOCK_DURATION|" /opt/tblocker/config.yaml
        else
            echo "BlockDuration: $BLOCK_DURATION" | sudo tee -a /opt/tblocker/config.yaml
        fi

        if [[ "$WEBHOOK_NEEDED" == "y" || "$WEBHOOK_NEEDED" == "Y" ]]; then
            if grep -q "^SendWebhook:" /opt/tblocker/config.yaml; then
                sudo sed -i 's|^SendWebhook:.*$|SendWebhook: true|' /opt/tblocker/config.yaml
            else
                echo "SendWebhook: true" | sudo tee -a /opt/tblocker/config.yaml
            fi
            
            if grep -q "^WebhookURL:" /opt/tblocker/config.yaml; then
                sudo sed -i "s|^WebhookURL:.*$|WebhookURL: \"https://$WEBHOOK_URL\"|" /opt/tblocker/config.yaml
            else
                echo "WebhookURL: \"https://$WEBHOOK_URL\"" | sudo tee -a /opt/tblocker/config.yaml
            fi

            if ! grep -q "^WebhookTemplate:" /opt/tblocker/config.yaml; then
                echo "WebhookTemplate: '{\"username\":\"%s\",\"ip\":\"%s\",\"server\":\"%s\",\"action\":\"%s\",\"duration\":%d,\"timestamp\":\"%s\"}'" | sudo tee -a /opt/tblocker/config.yaml
            fi

            if ! grep -q "^WebhookHeaders:" /opt/tblocker/config.yaml; then
                echo "WebhookHeaders:" | sudo tee -a /opt/tblocker/config.yaml
                echo "  Content-Type: \"application/json\"" | sudo tee -a /opt/tblocker/config.yaml
            fi
        else
            if grep -q "^SendWebhook:" /opt/tblocker/config.yaml; then
                sudo sed -i 's|^SendWebhook:.*$|SendWebhook: false|' /opt/tblocker/config.yaml
            else
                echo "SendWebhook: false" | sudo tee -a /opt/tblocker/config.yaml
            fi
        fi
        
        sudo systemctl restart tblocker.service
        success "$(get_string "install_tblocker_config_updated")"
    else
        error "$(get_string "install_tblocker_config_error")"
        exit 1
    fi
}

main() {
    if check_tblocker; then
        question "$(get_string "install_tblocker_enter_block_duration")"
        BLOCK_DURATION="$REPLY"
        BLOCK_DURATION=${BLOCK_DURATION:-10}

        check_webhook
        export WEBHOOK_NEEDED
        export WEBHOOK_URL="${WEBHOOK_URL:-}"

        setup_logs_and_logrotate
        
        if check_remnanode; then
            update_docker_compose
        fi

        update_tblocker_config
    else
        question "$(get_string "install_tblocker_enter_block_duration")"
        BLOCK_DURATION="$REPLY"
        BLOCK_DURATION=${BLOCK_DURATION:-10}

        check_webhook
        export WEBHOOK_NEEDED
        export WEBHOOK_URL="${WEBHOOK_URL:-}"

        setup_logs_and_logrotate
        
        if check_remnanode; then
            update_docker_compose
        fi

        install_iptables
        install_tblocker
    fi

    success "$(get_string "install_tblocker_complete")"
    read -n 1 -s -r -p "$(get_string "install_tblocker_press_key")"
    exit 0
}

main
