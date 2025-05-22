#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"
source "/opt/remnasetup/scripts/common/languages.sh"

check_remnanode() {
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
    info "$(get_string "install_tblocker_update_compose")"
    cd /opt/remnanode
    sudo docker compose down
    rm -f docker-compose.yml
    cp "/opt/remnasetup/data/docker/node-tblocker-compose.yml" docker-compose.yml
    sudo docker compose up -d
    success "$(get_string "install_tblocker_compose_updated")"
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
                return 1
            else
                warn "$(get_string "install_tblocker_please_enter_yn")"
            fi
        done
    fi
    return 0
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

setup_crontab() {
    info "$(get_string "install_tblocker_setup_crontab")"
    crontab -l > /tmp/crontab_tmp 2>/dev/null || true
    echo "0 * * * * truncate -s 0 /var/lib/toblock/access.log" >> /tmp/crontab_tmp
    echo "0 * * * * truncate -s 0 /var/lib/toblock/error.log" >> /tmp/crontab_tmp

    crontab /tmp/crontab_tmp
    rm /tmp/crontab_tmp
    success "$(get_string "install_tblocker_crontab_configured")"
}

install_tblocker() {
    info "$(get_string "install_tblocker_installing")"
    sudo mkdir -p /opt/tblocker
    sudo chmod -R 777 /opt/tblocker
    sudo mkdir -p /var/lib/toblock
    sudo chmod -R 777 /var/lib/toblock
    sudo su - << 'ROOT_EOF'
source /tmp/install_vars

curl -fsSL git.new/install -o /tmp/tblocker-install.sh || {
    error "$(get_string "install_tblocker_download_error")"
    exit 1
}

printf "\n\n\n" | bash /tmp/tblocker-install.sh || {
    error "$(get_string "install_tblocker_script_error")"
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
    error "$(get_string "install_tblocker_config_error")"
    exit 1
fi

exit
ROOT_EOF

    sudo systemctl restart tblocker.service
    success "$(get_string "install_tblocker_installed_success")"
}

update_tblocker_config() {
    info "$(get_string "install_tblocker_updating_config")"
    if [[ -f /opt/tblocker/config.yaml ]]; then
        sudo sed -i 's|^LogFile:.*$|LogFile: "/var/lib/toblock/access.log"|' /opt/tblocker/config.yaml
        sudo sed -i 's|^UsernameRegex:.*$|UsernameRegex: "email: (\\\\S+)"|' /opt/tblocker/config.yaml
        sudo sed -i "s|^AdminBotToken:.*$|AdminBotToken: \"$ADMIN_BOT_TOKEN\"|" /opt/tblocker/config.yaml
        sudo sed -i "s|^AdminChatID:.*$|AdminChatID: \"$ADMIN_CHAT_ID\"|" /opt/tblocker/config.yaml
        sudo sed -i "s|^BlockDuration:.*$|BlockDuration: $BLOCK_DURATION|" /opt/tblocker/config.yaml

        if [[ "$WEBHOOK_NEEDED" == "y" || "$WEBHOOK_NEEDED" == "Y" ]]; then
            sudo sed -i 's|^SendWebhook:.*$|SendWebhook: true|' /opt/tblocker/config.yaml
            sudo sed -i "s|^WebhookURL:.*$|WebhookURL: \"https://$WEBHOOK_URL\"|" /opt/tblocker/config.yaml
        else
            sudo sed -i 's|^SendWebhook:.*$|SendWebhook: false|' /opt/tblocker/config.yaml
        fi
        
        sudo systemctl restart tblocker.service
        success "$(get_string "install_tblocker_config_updated")"
    else
        error "$(get_string "install_tblocker_config_error")"
        exit 1
    fi
}

main() {
    if check_remnanode; then
        update_docker_compose
    fi

    if check_tblocker; then
        while true; do
            question "$(get_string "install_tblocker_enter_bot_token")"
            ADMIN_BOT_TOKEN="$REPLY"
            if [[ -n "$ADMIN_BOT_TOKEN" ]]; then
                break
            fi
            warn "$(get_string "install_tblocker_bot_token_empty")"
        done
        echo "ADMIN_BOT_TOKEN=$ADMIN_BOT_TOKEN" > /tmp/install_vars

        while true; do
            question "$(get_string "install_tblocker_enter_chat_id")"
            ADMIN_CHAT_ID="$REPLY"
            if [[ -n "$ADMIN_CHAT_ID" ]]; then
                break
            fi
            warn "$(get_string "install_tblocker_chat_id_empty")"
        done
        echo "ADMIN_CHAT_ID=$ADMIN_CHAT_ID" >> /tmp/install_vars

        question "$(get_string "install_tblocker_enter_block_duration")"
        BLOCK_DURATION="$REPLY"
        BLOCK_DURATION=${BLOCK_DURATION:-10}
        echo "BLOCK_DURATION=$BLOCK_DURATION" >> /tmp/install_vars

        check_webhook
        if [[ "$WEBHOOK_NEEDED" == "y" || "$WEBHOOK_NEEDED" == "Y" ]]; then
            echo "WEBHOOK_URL=$WEBHOOK_URL" >> /tmp/install_vars
        fi

        export WEBHOOK_NEEDED
        export WEBHOOK_URL

        update_tblocker_config
    else
        while true; do
            question "$(get_string "install_tblocker_enter_bot_token")"
            ADMIN_BOT_TOKEN="$REPLY"
            if [[ -n "$ADMIN_BOT_TOKEN" ]]; then
                break
            fi
            warn "$(get_string "install_tblocker_bot_token_empty")"
        done
        echo "ADMIN_BOT_TOKEN=$ADMIN_BOT_TOKEN" > /tmp/install_vars

        while true; do
            question "$(get_string "install_tblocker_enter_chat_id")"
            ADMIN_CHAT_ID="$REPLY"
            if [[ -n "$ADMIN_CHAT_ID" ]]; then
                break
            fi
            warn "$(get_string "install_tblocker_chat_id_empty")"
        done
        echo "ADMIN_CHAT_ID=$ADMIN_CHAT_ID" >> /tmp/install_vars

        question "$(get_string "install_tblocker_enter_block_duration")"
        BLOCK_DURATION="$REPLY"
        BLOCK_DURATION=${BLOCK_DURATION:-10}
        echo "BLOCK_DURATION=$BLOCK_DURATION" >> /tmp/install_vars

        check_webhook
        if [[ "$WEBHOOK_NEEDED" == "y" || "$WEBHOOK_NEEDED" == "Y" ]]; then
            echo "WEBHOOK_URL=$WEBHOOK_URL" >> /tmp/install_vars
        fi

        export WEBHOOK_NEEDED
        export WEBHOOK_URL

        install_tblocker
        setup_crontab
    fi

    rm -f /tmp/install_vars
    success "$(get_string "install_tblocker_complete")"
    read -n 1 -s -r -p "$(get_string "install_tblocker_press_key")"
    exit 0
}

main
