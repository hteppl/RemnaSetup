#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

REINSTALL_PANEL=false
REINSTALL_SUBSCRIPTION=false
REINSTALL_CADDY=false

check_component() {
    local component=$1
    local path=$2
    local env_file=$3

    if [ -d "$path" ]; then
        info "Обнаружена установка $component"
        question "Переустановить $component? (y/n): "
        REINSTALL="$REPLY"

        if [ "$REINSTALL" = "y" ]; then
            warn "Останавливаем и удаляем существующую установку..."
            cd "$path" || exit 1
            docker compose down
            cd - || exit 1

            if [ -n "$env_file" ] && [ -f "$env_file" ]; then
                rm -f "$env_file"
            fi

            if [ -f "$path/docker-compose.yml" ]; then
                rm -f "$path/docker-compose.yml"
            fi

            case $component in
                "panel")
                    docker rmi remnawave/panel:latest 2>/dev/null || true
                    docker rmi remnawave/redis:latest 2>/dev/null || true
                    docker rmi remnawave/postgres:latest 2>/dev/null || true
                    REINSTALL_PANEL=true
                    ;;
                "subscription")
                    docker rmi remnawave/subscription-page:latest 2>/dev/null || true
                    REINSTALL_SUBSCRIPTION=true
                    ;;
                "caddy")
                    docker rmi caddy:latest 2>/dev/null || true
                    REINSTALL_CADDY=true
                    ;;
            esac
        else
            info "Отказано в переустановке $component"
        fi
    else
        case $component in
            "panel")
                REINSTALL_PANEL=true
                ;;
            "subscription")
                REINSTALL_SUBSCRIPTION=true
                ;;
            "caddy")
                REINSTALL_CADDY=true
                ;;
        esac
    fi
}

install_docker() {
    if ! command -v docker &> /dev/null; then
        info "Установка Docker..."
        sudo curl -fsSL https://get.docker.com | sh
    fi
}

generate_jwt() {
    openssl rand -hex 64
}

install_without_protection() {
    if [ "$REINSTALL_PANEL" = true ]; then
        info "Установка панели Remnawave..."
        mkdir -p /opt/remnawave
        cp "/opt/remnasetup/data/docker/panel.env" /opt/remnawave/.env
        cp "/opt/remnasetup/data/docker/panel-compose.yml" /opt/remnawave/docker-compose.yml

        JWT_AUTH_SECRET=$(generate_jwt)
        JWT_API_TOKENS_SECRET=$(generate_jwt)

        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" /opt/remnawave/.env
        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" /opt/remnawave/.env
        sed -i "s|\$METRICS_USER|$METRICS_USER|g" /opt/remnawave/.env
        sed -i "s|\$METRICS_PASS|$METRICS_PASS|g" /opt/remnawave/.env
        sed -i "s|\$DB_USER|$DB_USER|g" /opt/remnawave/.env
        sed -i "s|\$DB_PASSWORD|$DB_PASSWORD|g" /opt/remnawave/.env
        sed -i "s|\$JWT_AUTH_SECRET|$JWT_AUTH_SECRET|g" /opt/remnawave/.env
        sed -i "s|\$JWT_API_TOKENS_SECRET|$JWT_API_TOKENS_SECRET|g" /opt/remnawave/.env
        sed -i "s|\$SUB_DOMAIN|$SUB_DOMAIN|g" /opt/remnawave/.env

        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" /opt/remnawave/docker-compose.yml

        cd /opt/remnawave && docker compose up -d
    fi

    if [ "$REINSTALL_SUBSCRIPTION" = true ]; then
        info "Установка страницы подписок..."
        mkdir -p /opt/remnawave/subscription
        cp "/opt/remnasetup/data/app-config.json" /opt/remnawave/subscription/app-config.json
        cp "/opt/remnasetup/data/docker/subscription-compose.yml" /opt/remnawave/subscription/docker-compose.yml

        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$PROJECT_NAME|$PROJECT_NAME|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$PROJECT_DESCRIPTION|$PROJECT_DESCRIPTION|g" /opt/remnawave/subscription/docker-compose.yml

        cd /opt/remnawave/subscription && docker compose up -d
    fi

    if [ "$REINSTALL_CADDY" = true ]; then
        info "Установка Caddy..."
        mkdir -p /opt/remnawave/caddy
        cp "/opt/remnasetup/data/caddy/caddyfile" /opt/remnawave/caddy/Caddyfile
        cp "/opt/remnasetup/data/docker/caddy-compose.yml" /opt/remnawave/caddy/docker-compose.yml

        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" /opt/remnawave/caddy/Caddyfile
        sed -i "s|\$SUB_DOMAIN|$SUB_DOMAIN|g" /opt/remnawave/caddy/Caddyfile
        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" /opt/remnawave/caddy/Caddyfile
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" /opt/remnawave/caddy/Caddyfile

        cd /opt/remnawave/caddy && docker compose up -d
    fi
}

install_with_protection() {
    if [ "$REINSTALL_PANEL" = true ]; then
        info "Установка панели Remnawave с защитой..."
        mkdir -p /opt/remnawave
        cp "/opt/remnasetup/data/docker/panel.env" /opt/remnawave/.env
        cp "/opt/remnasetup/data/docker/panel-compose.yml" /opt/remnawave/docker-compose.yml

        JWT_AUTH_SECRET=$(generate_jwt)
        JWT_API_TOKENS_SECRET=$(generate_jwt)

        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" /opt/remnawave/.env
        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" /opt/remnawave/.env
        sed -i "s|\$METRICS_USER|$METRICS_USER|g" /opt/remnawave/.env
        sed -i "s|\$METRICS_PASS|$METRICS_PASS|g" /opt/remnawave/.env
        sed -i "s|\$DB_USER|$DB_USER|g" /opt/remnawave/.env
        sed -i "s|\$DB_PASSWORD|$DB_PASSWORD|g" /opt/remnawave/.env
        sed -i "s|\$JWT_AUTH_SECRET|$JWT_AUTH_SECRET|g" /opt/remnawave/.env
        sed -i "s|\$JWT_API_TOKENS_SECRET|$JWT_API_TOKENS_SECRET|g" /opt/remnawave/.env
        sed -i "s|\$SUB_DOMAIN|$SUB_DOMAIN|g" /opt/remnawave/.env

        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" /opt/remnawave/docker-compose.yml

        cd /opt/remnawave && docker compose up -d
    fi

    if [ "$REINSTALL_SUBSCRIPTION" = true ]; then
        info "Установка страницы подписок с защитой..."
        mkdir -p /opt/remnawave/subscription
        cp "/opt/remnasetup/data/app-config.json" /opt/remnawave/subscription/app-config.json
        cp "/opt/remnasetup/data/docker/subscription-protection-compose.yml" /opt/remnawave/subscription/docker-compose.yml

        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$PROJECT_NAME|$PROJECT_NAME|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$PROJECT_DESCRIPTION|$PROJECT_DESCRIPTION|g" /opt/remnawave/subscription/docker-compose.yml

        cd /opt/remnawave/subscription && docker compose up -d
    fi

    if [ "$REINSTALL_CADDY" = true ]; then
        info "Установка Caddy с защитой..."
        mkdir -p /opt/remnawave/caddy
        cp "/opt/remnasetup/data/caddy/caddyfile-protection" /opt/remnawave/caddy/Caddyfile
        cp "/opt/remnasetup/data/docker/caddy-protection-compose.yml" /opt/remnawave/caddy/docker-compose.yml

        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" /opt/remnawave/caddy/Caddyfile
        sed -i "s|\$SUB_DOMAIN|$SUB_DOMAIN|g" /opt/remnawave/caddy/Caddyfile
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" /opt/remnawave/caddy/Caddyfile

        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" /opt/remnawave/caddy/docker-compose.yml
        sed -i "s|\$PANEL_PATH|$PANEL_PATH|g" /opt/remnawave/caddy/docker-compose.yml
        sed -i "s|\$ADMIN_USERNAME|$ADMIN_USERNAME|g" /opt/remnawave/caddy/docker-compose.yml
        sed -i "s|\$ADMIN_EMAIL|$ADMIN_EMAIL|g" /opt/remnawave/caddy/docker-compose.yml
        sed -i "s|\$ADMIN_PASSWORD|$ADMIN_PASSWORD|g" /opt/remnawave/caddy/docker-compose.yml

        cd /opt/remnawave/caddy && docker compose up -d
    fi
}

check_docker() {
    if command -v docker >/dev/null 2>&1; then
        info "Docker уже установлен, пропускаем установку."
        return 0
    else
        return 1
    fi
}

main() {
    check_component "panel" "/opt/remnawave" "/opt/remnawave/.env"
    check_component "subscription" "/opt/remnawave/subscription" "/opt/remnawave/subscription/.env"
    check_component "caddy" "/opt/remnawave/caddy" "/opt/remnawave/caddy/.env"

    question "Требуется ли защита панели кастомным путем и защита подписок? (y/n): "
    NEED_PROTECTION="$REPLY"

    while true; do
        question "Введите домен панели (например, panel.domain.com): "
        PANEL_DOMAIN="$REPLY"
        if [[ -n "$PANEL_DOMAIN" ]]; then
            break
        fi
        warn "Домен панели не может быть пустым. Пожалуйста, введите значение."
    done

    while true; do
        question "Введите домен подписок (например, sub.domain.com): "
        SUB_DOMAIN="$REPLY"
        if [[ -n "$SUB_DOMAIN" ]]; then
            break
        fi
        warn "Домен подписок не может быть пустым. Пожалуйста, введите значение."
    done

    question "Введите порт панели (по умолчанию 3000): "
    PANEL_PORT="$REPLY"
    PANEL_PORT=${PANEL_PORT:-3000}

    question "Введите порт подписок (по умолчанию 3010): "
    SUB_PORT="$REPLY"
    SUB_PORT=${SUB_PORT:-3010}

    while true; do
        question "Введите логин для метрик: "
        METRICS_USER="$REPLY"
        if [[ -n "$METRICS_USER" ]]; then
            break
        fi
        warn "Логин для метрик не может быть пустым. Пожалуйста, введите значение."
    done

    while true; do
        question "Введите пароль для метрик: "
        METRICS_PASS="$REPLY"
        if [[ -n "$METRICS_PASS" ]]; then
            break
        fi
        warn "Пароль для метрик не может быть пустым. Пожалуйста, введите значение."
    done

    while true; do
        question "Введите имя пользователя базы данных: "
        DB_USER="$REPLY"
        if [[ -n "$DB_USER" ]]; then
            break
        fi
        warn "Имя пользователя базы данных не может быть пустым. Пожалуйста, введите значение."
    done

    while true; do
        question "Введите пароль пользователя базы данных: "
        DB_PASSWORD="$REPLY"
        if [[ -n "$DB_PASSWORD" ]]; then
            break
        fi
        warn "Пароль пользователя базы данных не может быть пустым. Пожалуйста, введите значение."
    done

    while true; do
        question "Введите имя проекта: "
        PROJECT_NAME="$REPLY"
        if [[ -n "$PROJECT_NAME" ]]; then
            break
        fi
        warn "Имя проекта не может быть пустым. Пожалуйста, введите значение."
    done

    while true; do
        question "Введите описание страницы подписки: "
        PROJECT_DESCRIPTION="$REPLY"
        if [[ -n "$PROJECT_DESCRIPTION" ]]; then
            break
        fi
        warn "Описание проекта не может быть пустым. Пожалуйста, введите значение."
    done

    if [ "$NEED_PROTECTION" = "y" ]; then
        while true; do
            question "Введите путь доступа к панели (например, supersecretroute): "
            PANEL_PATH="$REPLY"
            if [[ -n "$PANEL_PATH" ]]; then
                break
            fi
            warn "Путь доступа к панели не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите логин администратора: "
            ADMIN_USERNAME="$REPLY"
            if [[ -n "$ADMIN_USERNAME" ]]; then
                break
            fi
            warn "Логин администратора не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите email администратора: "
            ADMIN_EMAIL="$REPLY"
            if [[ -n "$ADMIN_EMAIL" ]]; then
                break
            fi
            warn "Email администратора не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите пароль администратора: "
            ADMIN_PASSWORD="$REPLY"
            if [[ -n "$ADMIN_PASSWORD" ]]; then
                break
            fi
            warn "Пароль администратора не может быть пустым. Пожалуйста, введите значение."
        done
    fi

    if ! check_docker; then
        install_docker
    fi
    if [ "$NEED_PROTECTION" = "y" ]; then
        install_with_protection
    else
        install_without_protection
    fi

    success "Установка завершена!"
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    exit 0
}

main
