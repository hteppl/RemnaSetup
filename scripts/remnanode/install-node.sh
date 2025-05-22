#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"
source "/opt/remnasetup/scripts/common/languages.sh"

check_docker() {
    if command -v docker >/dev/null 2>&1; then
        info "$(get_string "install_node_docker_installed")"
        return 0
    else
        return 1
    fi
}

install_docker() {
    info "$(get_string "install_node_installing_docker")"
    sudo curl -fsSL https://get.docker.com | sh || {
        error "$(get_string "install_node_docker_error")"
        exit 1
    }
    success "$(get_string "install_node_docker_success")"
}

check_remnanode() {
    if [ -f "/opt/remnanode/docker-compose.yml" ]; then
        info "$(get_string "install_node_already_installed")"
        while true; do
            question "$(get_string "install_node_update_settings")"
            REINSTALL="$REPLY"
            if [[ "$REINSTALL" == "y" || "$REINSTALL" == "Y" ]]; then
                return 0
            elif [[ "$REINSTALL" == "n" || "$REINSTALL" == "N" ]]; then
                info "$(get_string "install_node_already_installed")"
                read -n 1 -s -r -p "$(get_string "install_node_press_key")"
                exit 0
                return 1
            else
                warn "$(get_string "install_node_please_enter_yn")"
            fi
        done
    fi
    return 0
}

install_remnanode() {
    info "$(get_string "install_node_installing")"
    sudo chmod -R 777 /opt
    mkdir -p /opt/remnanode
    sudo chown $USER:$USER /opt/remnanode
    cd /opt/remnanode

    echo "APP_PORT=$APP_PORT" > .env
    echo "$SSL_CERT_FULL" >> .env

    if [[ "$USE_TBLOCKER" == "y" || "$USE_TBLOCKER" == "Y" ]]; then
        cp "/opt/remnasetup/data/docker/node-tblocker-compose.yml" docker-compose.yml
    else
        cp "/opt/remnasetup/data/docker/node-compose.yml" docker-compose.yml
    fi

    sudo docker compose up -d || {
        error "$(get_string "install_node_error")"
        exit 1
    }
    success "$(get_string "install_node_success")"
}

main() {
    if check_remnanode; then
        cd /opt/remnanode
        sudo docker compose down
    fi

    while true; do
        question "$(get_string "install_node_enter_app_port")"
        APP_PORT="$REPLY"
        APP_PORT=${APP_PORT:-3001}
        if [[ "$APP_PORT" =~ ^[0-9]+$ ]]; then
            break
        fi
        warn "$(get_string "install_node_port_must_be_number")"
    done

    while true; do
        question "$(get_string "install_node_enter_ssl_cert")"
        SSL_CERT_FULL="$REPLY"
        if [[ -n "$SSL_CERT_FULL" ]]; then
            break
        fi
        warn "$(get_string "install_node_ssl_cert_empty")"
    done

    while true; do
        question "$(get_string "install_node_use_tblocker")"
        USE_TBLOCKER="$REPLY"
        if [[ "$USE_TBLOCKER" == "y" || "$USE_TBLOCKER" == "Y" || "$USE_TBLOCKER" == "n" || "$USE_TBLOCKER" == "N" ]]; then
            break
        fi
        warn "$(get_string "install_node_please_enter_yn")"
    done

    if ! check_docker; then
        install_docker
    fi

    install_remnanode

    success "$(get_string "install_node_complete")"
    read -n 1 -s -r -p "$(get_string "install_node_press_key")"
    exit 0
}

main 