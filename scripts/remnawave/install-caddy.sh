#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

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

            docker rmi caddy:latest 2>/dev/null || true

            REINSTALL_CADDY=true
        else
            info "Отказано в переустановке $component"
            read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
            exit 0
        fi
    else
        REINSTALL_CADDY=true
    fi
}

install_docker() {
    if ! command -v docker &> /dev/null; then
        info "Установка Docker..."
        sudo curl -fsSL https://get.docker.com | sh
    fi
}

install_without_protection() {
    if [ "$REINSTALL_CADDY" = true ]; then
        info "Установка Caddy..."
        mkdir -p /opt/remnawave/caddy
        cp "/opt/remnasetup/data/caddy/caddyfile" /opt/remnawave/caddy/Caddyfile
        cp "/opt/remnasetup/data/docker/caddy-compose.yml" /opt/remnawave/caddy/docker-compose.yml

        sed -i "s|PANEL_DOMAIN=.*|PANEL_DOMAIN=$PANEL_DOMAIN|g" /opt/remnawave/.env
        sed -i "s|SUB_DOMAIN=.*|SUB_DOMAIN=$SUB_DOMAIN|g" /opt/remnawave/.env
        sed -i "s|PANEL_PORT=.*|PANEL_PORT=$PANEL_PORT|g" /opt/remnawave/.env

        sed -i "s|PANEL_DOMAIN=.*|PANEL_DOMAIN=$PANEL_DOMAIN|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|SUB_PORT=.*|SUB_PORT=$SUB_PORT|g" /opt/remnawave/subscription/docker-compose.yml

        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" /opt/remnawave/caddy/Caddyfile
        sed -i "s|\$SUB_DOMAIN|$SUB_DOMAIN|g" /opt/remnawave/caddy/Caddyfile
        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" /opt/remnawave/caddy/Caddyfile
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" /opt/remnawave/caddy/Caddyfile

        cd /opt/remnawave && docker compose restart
        cd /opt/remnawave/subscription && docker compose restart

        cd /opt/remnawave/caddy && docker compose up -d
    fi
}

install_with_protection() {
    if [ "$REINSTALL_CADDY" = true ]; then
        info "Установка Caddy с защитой..."
        mkdir -p /opt/remnawave/caddy
        cp "/opt/remnasetup/data/caddy/caddyfile-protection" /opt/remnawave/caddy/Caddyfile
        cp "/opt/remnasetup/data/docker/caddy-protection-compose.yml" /opt/remnawave/caddy/docker-compose.yml

        sed -i "s|PANEL_DOMAIN=.*|PANEL_DOMAIN=$PANEL_DOMAIN|g" /opt/remnawave/.env
        sed -i "s|SUB_DOMAIN=.*|SUB_DOMAIN=$SUB_DOMAIN|g" /opt/remnawave/.env
        sed -i "s|PANEL_PORT=.*|PANEL_PORT=$PANEL_PORT|g" /opt/remnawave/.env

        cd /opt/remnawave/subscription && docker compose down
        rm -f docker-compose.yml
        cp "/opt/remnasetup/data/docker/subscription-protection-compose.yml" /opt/remnawave/subscription/docker-compose.yml

        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$PROJECT_NAME|$PROJECT_NAME|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$PROJECT_DESCRIPTION|$PROJECT_DESCRIPTION|g" /opt/remnawave/subscription/docker-compose.yml

        sed -i "s|\$REMNAWAVE_PANEL_DOMAIN|$PANEL_DOMAIN|g" /opt/remnawave/caddy/docker-compose.yml
        sed -i "s|\$REMNAWAVE_CUSTOM_LOGIN_ROUTE|$CUSTOM_LOGIN_ROUTE|g" /opt/remnawave/caddy/docker-compose.yml
        sed -i "s|\$AUTHP_ADMIN_USER|$LOGIN_USERNAME|g" /opt/remnawave/caddy/docker-compose.yml
        sed -i "s|\$AUTHP_ADMIN_EMAIL|$LOGIN_EMAIL|g" /opt/remnawave/caddy/docker-compose.yml
        sed -i "s|\$AUTHP_ADMIN_SECRET|$LOGIN_PASSWORD|g" /opt/remnawave/caddy/docker-compose.yml

        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" /opt/remnawave/caddy/Caddyfile
        sed -i "s|\$SUB_DOMAIN|$SUB_DOMAIN|g" /opt/remnawave/caddy/Caddyfile
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" /opt/remnawave/caddy/Caddyfile

        cd /opt/remnawave && docker compose restart
        cd /opt/remnawave/subscription && docker compose up -d

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

    if [ "$NEED_PROTECTION" = "y" ]; then
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

        while true; do
            question "Введите путь доступа к панели (например, supersecretroute): "
            CUSTOM_LOGIN_ROUTE="$REPLY"
            if [[ -n "$CUSTOM_LOGIN_ROUTE" ]]; then
                break
            fi
            warn "Путь доступа к панели не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите логин администратора: "
            LOGIN_USERNAME="$REPLY"
            if [[ -n "$LOGIN_USERNAME" ]]; then
                break
            fi
            warn "Логин администратора не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите email администратора: "
            LOGIN_EMAIL="$REPLY"
            if [[ -n "$LOGIN_EMAIL" ]]; then
                break
            fi
            warn "Email администратора не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите пароль администратора: "
            LOGIN_PASSWORD="$REPLY"
            if [[ -n "$LOGIN_PASSWORD" ]]; then
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
