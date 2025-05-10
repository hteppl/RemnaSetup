#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

REINSTALL_PANEL=false

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

            docker rmi remnawave/panel:latest 2>/dev/null || true
            docker rmi remnawave/redis:latest 2>/dev/null || true
            docker rmi remnawave/postgres:latest 2>/dev/null || true
            REINSTALL_PANEL=true
        else
            info "Отказано в переустановке $component"
            read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
            exit 0
        fi
    else
        REINSTALL_PANEL=true
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

install_panel() {
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

    if ! check_docker; then
        install_docker
    fi
    install_panel

    success "Установка завершена!"
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    exit 0
}

main
