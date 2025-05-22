#!/bin/bash

source "/opt/remnasetup/scripts/common/languages.sh"
source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

REINSTALL_PANEL=false

check_component() {
    if [ -f "/opt/remnawave/docker-compose.yml" ] && (cd /opt/remnawave && docker compose ps -q | grep -q "remnawave\|remnawave-db\|remnawave-redis") || [ -f "/opt/remnawave/.env" ]; then
        info "$(get_string "install_panel_detected")"
        while true; do
            question "$(get_string "install_panel_reinstall")"
            REINSTALL="$REPLY"
            if [[ "$REINSTALL" == "y" || "$REINSTALL" == "Y" ]]; then
                warn "$(get_string "install_panel_stopping")"
                cd /opt/remnawave && docker compose down
                docker rmi remnawave/backend:latest postgres:17 valkey/valkey:8.0.2-alpine 2>/dev/null || true
                docker volume rm remnawave-db-data remnawave-redis-data 2>/dev/null || true
                rm -f /opt/remnawave/.env
                rm -f /opt/remnawave/docker-compose.yml
                REINSTALL_PANEL=true
                break
            elif [[ "$REINSTALL" == "n" || "$REINSTALL" == "N" ]]; then
                info "$(get_string "install_panel_reinstall_denied")"
                read -n 1 -s -r -p "$(get_string "install_panel_press_key")"
                exit 1
            else
                warn "$(get_string "install_panel_please_enter_yn")"
            fi
        done
    else
        REINSTALL_PANEL=true
    fi
}

install_docker() {
    if ! command -v docker &> /dev/null; then
        info "$(get_string "install_panel_installing_docker")"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
    fi
}

generate_jwt() {
    openssl rand -hex 64
}

generate_short_ids() {
    local ids=""
    for i in {1..20}; do
        id=$(openssl rand -hex 8)
        if [ $i -eq 20 ]; then
            ids="${ids}\"$id\""
        else
            ids="${ids}\"$id\",\n"
        fi
    done
    printf "%s" "$ids"
}

generate_reality_keys() {
    docker run --rm ghcr.io/xtls/xray-core x25519 > /tmp/xray_keys.txt 2>&1
    local keys=$(cat /tmp/xray_keys.txt)
    rm -f /tmp/xray_keys.txt

    if [ -z "$keys" ]; then
        exit 1
    fi

    local private_key=$(echo "$keys" | grep "Private key:" | awk '{print $3}')
    local public_key=$(echo "$keys" | grep "Public key:" | awk '{print $3}')

    printf "%s\n%s" "$private_key" "$public_key"
}

update_xray_config() {
    local max_attempts=30
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker exec -i remnawave-db psql -U "$DB_USER" -d postgres -tAc "SELECT to_regclass('public.xray_config');" | grep -q xray_config; then
            break
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    if [ $attempt -gt $max_attempts ]; then
        return 0
    fi

    local uuid=$(docker exec -i remnawave-db psql -U "$DB_USER" -d postgres -t -c "SELECT uuid FROM xray_config LIMIT 1;" | tr -d '[:space:]')
    if [ -z "$uuid" ]; then
        return 0
    fi

    local short_ids=$(generate_short_ids)
    local keys_output=$(generate_reality_keys)
    local private_key=$(echo "$keys_output" | head -n1)
    local public_key=$(echo "$keys_output" | tail -n1)
    
    local config_template=$(cat "/opt/remnasetup/data/config/xray_config.json")
    
    local config=$(echo "$config_template" | \
        sed "s/\$short_id/$short_ids/g" | \
        sed "s/\$public_key/$public_key/g" | \
        sed "s/\$private_key/$private_key/g")

    config=$(echo "$config" | sed "s/'/''/g")

    docker exec -i remnawave-db psql -U "$DB_USER" -d postgres -c "UPDATE xray_config SET config = '$config'::jsonb WHERE uuid = '$uuid';" >/dev/null 2>&1
}

install_panel() {
    if [ "$REINSTALL_PANEL" = true ]; then
        info "$(get_string "install_panel_installing")"
        mkdir -p /opt/remnawave
        cd /opt/remnawave

        cp "/opt/remnasetup/data/docker/panel.env" .env
        cp "/opt/remnasetup/data/docker/panel-compose.yml" docker-compose.yml

        JWT_AUTH_SECRET=$(generate_jwt)
        JWT_API_TOKENS_SECRET=$(generate_jwt)

        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" .env
        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" .env
        sed -i "s|\$METRICS_USER|$METRICS_USER|g" .env
        sed -i "s|\$METRICS_PASS|$METRICS_PASS|g" .env
        sed -i "s|\$DB_USER|$DB_USER|g" .env
        sed -i "s|\$DB_PASSWORD|$DB_PASSWORD|g" .env
        sed -i "s|\$JWT_AUTH_SECRET|$JWT_AUTH_SECRET|g" .env
        sed -i "s|\$JWT_API_TOKENS_SECRET|$JWT_API_TOKENS_SECRET|g" .env
        sed -i "s|\$SUB_DOMAIN|$SUB_DOMAIN|g" .env

        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" docker-compose.yml

        docker compose up -d
    fi
}

check_docker() {
    if command -v docker >/dev/null 2>&1; then
        info "$(get_string "install_panel_docker_installed")"
        return 0
    else
        return 1
    fi
}

main() {
    check_component

    while true; do
        question "$(get_string "install_panel_enter_panel_domain")"
        PANEL_DOMAIN="$REPLY"
        if [[ -n "$PANEL_DOMAIN" ]]; then
            break
        fi
        warn "$(get_string "install_panel_domain_empty")"
    done

    while true; do
        question "$(get_string "install_panel_enter_sub_domain")"
        SUB_DOMAIN="$REPLY"
        if [[ -n "$SUB_DOMAIN" ]]; then
            break
        fi
        warn "$(get_string "install_panel_domain_empty")"
    done

    question "$(get_string "install_panel_enter_panel_port")"
    PANEL_PORT="$REPLY"
    PANEL_PORT=${PANEL_PORT:-3000}

    while true; do
        question "$(get_string "install_panel_enter_metrics_login")"
        METRICS_USER="$REPLY"
        if [[ -n "$METRICS_USER" ]]; then
            break
        fi
        warn "$(get_string "install_panel_metrics_login_empty")"
    done

    while true; do
        question "$(get_string "install_panel_enter_metrics_pass")"
        METRICS_PASS="$REPLY"
        if [[ -n "$METRICS_PASS" ]]; then
            break
        fi
        warn "$(get_string "install_panel_metrics_pass_empty")"
    done

    while true; do
        question "$(get_string "install_panel_enter_db_user")"
        DB_USER="$REPLY"
        if [[ -n "$DB_USER" ]]; then
            break
        fi
        warn "$(get_string "install_panel_db_user_empty")"
    done

    while true; do
        question "$(get_string "install_panel_enter_db_password")"
        DB_PASSWORD="$REPLY"
        if [[ -n "$DB_PASSWORD" ]]; then
            break
        fi
        warn "$(get_string "install_panel_db_password_empty")"
    done

    if ! check_docker; then
        install_docker
    fi
    install_panel

    update_xray_config

    success "$(get_string "install_panel_complete")"
    read -n 1 -s -r -p "$(get_string "install_panel_press_key")"
    exit 0
}

main
