#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

REINSTALL_SUBSCRIPTION=false

check_component() {
    if [ -f "/opt/remnawave/subscription/docker-compose.yml" ] && (cd /opt/remnawave/subscription && docker compose ps -q | grep -q "remnawave-subscription-page") || [ -f "/opt/remnawave/subscription/app-config.json" ]; then
        info "Обнаружена установка страницы подписок"
        question "Переустановить страницу подписок? (y/n): "
        REINSTALL="$REPLY"

        if [ "$REINSTALL" = "y" ]; then
            warn "Останавливаем и удаляем существующую установку..."
            cd /opt/remnawave/subscription && docker compose down
            docker rmi remnawave/subscription-page:latest 2>/dev/null || true
            rm -f /opt/remnawave/subscription/app-config.json
            rm -f /opt/remnawave/subscription/docker-compose.yml
            REINSTALL_SUBSCRIPTION=true
        else
            info "Отказано в переустановке страницы подписок"
            read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
            exit 0
        fi
    else
        REINSTALL_SUBSCRIPTION=true
    fi
}

install_docker() {
    if ! command -v docker &> /dev/null; then
        info "Установка Docker..."
        sudo curl -fsSL https://get.docker.com | sh
    fi
}

install_subscription() {
    if [ "$REINSTALL_SUBSCRIPTION" = true ]; then
        info "Установка страницы подписок Remnawave..."
        mkdir -p /opt/remnawave/subscription
        cp "/opt/remnasetup/data/app-config.json" /opt/remnawave/subscription/app-config.json
        cp "/opt/remnasetup/data/docker/subscription-compose.yml" /opt/remnawave/subscription/docker-compose.yml

        sed -i "s|SUB_DOMAIN=.*|SUB_DOMAIN=$SUB_DOMAIN|g" /opt/remnawave/.env

        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$PROJECT_NAME|$PROJECT_NAME|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$PROJECT_DESCRIPTION|$PROJECT_DESCRIPTION|g" /opt/remnawave/subscription/docker-compose.yml
        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" /opt/remnawave/subscription/docker-compose.yml

        cd /opt/remnawave && docker compose restart

        cd /opt/remnawave/subscription && docker compose up -d
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
    check_component

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

    question "Введите порт подписок (по умолчанию 3010): "
    SUB_PORT="$REPLY"
    SUB_PORT=${SUB_PORT:-3010}

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

    if ! check_docker; then
        install_docker
    fi
    install_subscription

    success "Установка завершена!"
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    exit 0
}

main
