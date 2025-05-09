#!/bin/bash

source "$(dirname "$0")/../../scripts/common/colors.sh"
source "$(dirname "$0")/../../scripts/common/functions.sh"

REINSTALL_CADDY=false

check_component() {
    local component=$1
    local path=$2
    local env_file=$3

    if [ -d "$path" ]; then
        info "Обнаружена установка $component"
        question "Переустановить $component? (y/n): "
        read -r REINSTALL

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
            "$(dirname "$0")/../../scripts/remnawave/menu.sh"
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
        cp "$(dirname "$0")/../../data/caddy/caddyfile" /opt/remnawave/caddy/Caddyfile
        cp "$(dirname "$0")/../../data/docker/caddy-compose.yml" /opt/remnawave/caddy/docker-compose.yml

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
        cp "$(dirname "$0")/../../data/caddy/caddyfile-protection" /opt/remnawave/caddy/Caddyfile
        cp "$(dirname "$0")/../../data/docker/caddy-protection-compose.yml" /opt/remnawave/caddy/docker-compose.yml

        sed -i "s|PANEL_DOMAIN=.*|PANEL_DOMAIN=$PANEL_DOMAIN|g" /opt/remnawave/.env
        sed -i "s|SUB_DOMAIN=.*|SUB_DOMAIN=$SUB_DOMAIN|g" /opt/remnawave/.env
        sed -i "s|PANEL_PORT=.*|PANEL_PORT=$PANEL_PORT|g" /opt/remnawave/.env

        cd /opt/remnawave/subscription && docker compose down
        rm -f docker-compose.yml
        cp "$(dirname "$0")/../../data/docker/subscription-protection-compose.yml" /opt/remnawave/subscription/docker-compose.yml

        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$PROJECT_NAME|$PROJECT_NAME|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$PROJECT_DESCRIPTION|$PROJECT_DESCRIPTION|g" /opt/remnawave/subscription/docker-compose.yml

        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" /opt/remnawave/caddy/docker-compose.yml
        sed -i "s|\$PANEL_PATH|$PANEL_PATH|g" /opt/remnawave/caddy/docker-compose.yml
        sed -i "s|\$ADMIN_USERNAME|$ADMIN_USERNAME|g" /opt/remnawave/caddy/docker-compose.yml
        sed -i "s|\$ADMIN_EMAIL|$ADMIN_EMAIL|g" /opt/remnawave/caddy/docker-compose.yml
        sed -i "s|\$ADMIN_PASSWORD|$ADMIN_PASSWORD|g" /opt/remnawave/caddy/docker-compose.yml

        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" /opt/remnawave/caddy/Caddyfile
        sed -i "s|\$SUB_DOMAIN|$SUB_DOMAIN|g" /opt/remnawave/caddy/Caddyfile
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" /opt/remnawave/caddy/Caddyfile

        cd /opt/remnawave && docker compose restart
        cd /opt/remnawave/subscription && docker compose up -d

        cd /opt/remnawave/caddy && docker compose up -d
    fi
}

main() {
    install_docker

    check_component "caddy" "/opt/remnawave/caddy" "/opt/remnawave/caddy/.env"

    question "Требуется ли защита панели кастомным путем и защита подписок? (y/n): "
    read -r NEED_PROTECTION

    while true; do
        question "Введите домен панели (например, panel.domain.com): "
        read -r PANEL_DOMAIN
        if [[ -n "$PANEL_DOMAIN" ]]; then
            break
        fi
        warn "Домен панели не может быть пустым. Пожалуйста, введите значение."
    done

    while true; do
        question "Введите домен подписок (например, sub.domain.com): "
        read -r SUB_DOMAIN
        if [[ -n "$SUB_DOMAIN" ]]; then
            break
        fi
        warn "Домен подписок не может быть пустым. Пожалуйста, введите значение."
    done

    question "Введите порт панели (по умолчанию 3000): "
    read -r PANEL_PORT
    PANEL_PORT=${PANEL_PORT:-3000}

    question "Введите порт подписок (по умолчанию 3010): "
    read -r SUB_PORT
    SUB_PORT=${SUB_PORT:-3010}

    if [ "$NEED_PROTECTION" = "y" ]; then
        while true; do
            question "Введите имя проекта: "
            read -r PROJECT_NAME
            if [[ -n "$PROJECT_NAME" ]]; then
                break
            fi
            warn "Имя проекта не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите описание страницы подписки: "
            read -r PROJECT_DESCRIPTION
            if [[ -n "$PROJECT_DESCRIPTION" ]]; then
                break
            fi
            warn "Описание проекта не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите путь доступа к панели (например, supersecretroute): "
            read -r PANEL_PATH
            if [[ -n "$PANEL_PATH" ]]; then
                break
            fi
            warn "Путь доступа к панели не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите логин администратора: "
            read -r ADMIN_USERNAME
            if [[ -n "$ADMIN_USERNAME" ]]; then
                break
            fi
            warn "Логин администратора не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите email администратора: "
            read -r ADMIN_EMAIL
            if [[ -n "$ADMIN_EMAIL" ]]; then
                break
            fi
            warn "Email администратора не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите пароль администратора: "
            read -r ADMIN_PASSWORD
            if [[ -n "$ADMIN_PASSWORD" ]]; then
                break
            fi
            warn "Пароль администратора не может быть пустым. Пожалуйста, введите значение."
        done
        
        install_with_protection
    else
        install_without_protection
    fi

    success "Установка завершена!"
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    "$(dirname "$0")/../../scripts/remnawave/menu.sh"
}

main
