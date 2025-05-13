#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

REINSTALL_CADDY=false

check_component() {
    if [ -f "/opt/remnawave/caddy/docker-compose.yml" ] || [ -f "/opt/remnawave/caddy/Caddyfile" ]; then
        info "Обнаружена установка Caddy"
        while true; do
            question "Переустановить Caddy? (y/n):"
            REINSTALL="$REPLY"
            if [[ "$REINSTALL" == "y" || "$REINSTALL" == "Y" ]]; then
                warn "Останавливаем и удаляем существующую установку..."
                if [ -f "/opt/remnawave/caddy/docker-compose.yml" ]; then
                    cd /opt/remnawave/caddy && docker compose down
                fi
                if docker ps -a --format '{{.Names}}' | grep -q "remnawave-caddy\|caddy"; then
                    if [ "$NEED_PROTECTION" = "y" ]; then
                        docker rmi remnawave/caddy-with-auth:latest 2>/dev/null || true
                    else
                        docker rmi caddy:2.9 2>/dev/null || true
                    fi
                fi
                rm -f /opt/remnawave/caddy/Caddyfile
                rm -f /opt/remnawave/caddy/docker-compose.yml
                REINSTALL_CADDY=true
                break
            elif [[ "$REINSTALL" == "n" || "$REINSTALL" == "N" ]]; then
                info "Отказано в переустановке Caddy"
                read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
                exit 0
            else
                warn "Пожалуйста, введите только 'y' или 'n'"
            fi
        done
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
        cd /opt/remnawave/caddy

        cp "/opt/remnasetup/data/caddy/caddyfile" Caddyfile
        cp "/opt/remnasetup/data/docker/caddy-compose.yml" docker-compose.yml

        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" Caddyfile
        sed -i "s|\$SUB_DOMAIN|$SUB_DOMAIN|g" Caddyfile
        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" Caddyfile
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" Caddyfile

        cd /opt/remnawave
        if [ -f ".env" ]; then
            sed -i "s|PANEL_DOMAIN=.*|PANEL_DOMAIN=$PANEL_DOMAIN|g" .env
            sed -i "s|SUB_DOMAIN=.*|SUB_DOMAIN=$SUB_DOMAIN|g" .env
            sed -i "s|PANEL_PORT=.*|PANEL_PORT=$PANEL_PORT|g" .env
        fi

        cd /opt/remnawave/subscription
        if [ -f "docker-compose.yml" ]; then
            sed -i "s|PANEL_DOMAIN=.*|PANEL_DOMAIN=$PANEL_DOMAIN|g" docker-compose.yml
            sed -i "s|SUB_PORT=.*|SUB_PORT=$SUB_PORT|g" docker-compose.yml
        fi

        cd /opt/remnawave && docker compose restart
        cd /opt/remnawave/subscription && docker compose restart
        cd /opt/remnawave/caddy && docker compose up -d
    fi
}

install_with_protection() {
    if [ "$REINSTALL_CADDY" = true ]; then
        info "Установка Caddy с защитой..."
        mkdir -p /opt/remnawave/caddy
        cd /opt/remnawave/caddy

        cp "/opt/remnasetup/data/caddy/caddyfile-protection" Caddyfile
        cp "/opt/remnasetup/data/docker/caddy-protection-compose.yml" docker-compose.yml

        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" docker-compose.yml
        sed -i "s|\$CUSTOM_LOGIN_ROUTE|$CUSTOM_LOGIN_ROUTE|g" docker-compose.yml
        sed -i "s|\$LOGIN_USERNAME|$LOGIN_USERNAME|g" docker-compose.yml
        sed -i "s|\$LOGIN_EMAIL|$LOGIN_EMAIL|g" docker-compose.yml
        sed -i "s|\$LOGIN_PASSWORD|$LOGIN_PASSWORD|g" docker-compose.yml

        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" Caddyfile
        sed -i "s|\$SUB_DOMAIN|$SUB_DOMAIN|g" Caddyfile
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" Caddyfile

        cd /opt/remnawave
        if [ -f ".env" ]; then
            sed -i "s|PANEL_DOMAIN=.*|PANEL_DOMAIN=$PANEL_DOMAIN|g" .env
            sed -i "s|SUB_DOMAIN=.*|SUB_DOMAIN=$SUB_DOMAIN|g" .env
            sed -i "s|PANEL_PORT=.*|PANEL_PORT=$PANEL_PORT|g" .env
        fi

        cd /opt/remnawave/subscription
        docker compose down
        rm -f docker-compose.yml
        cp "/opt/remnasetup/data/docker/subscription-protection-compose.yml" docker-compose.yml

        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" docker-compose.yml
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" docker-compose.yml
        sed -i "s|\$PROJECT_NAME|$PROJECT_NAME|g" docker-compose.yml
        sed -i "s|\$PROJECT_DESCRIPTION|$PROJECT_DESCRIPTION|g" docker-compose.yml

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
    check_component

    while true; do
        question "Требуется ли защита панели кастомным путем и защита подписок? (y/n):"
        NEED_PROTECTION="$REPLY"
        if [[ "$NEED_PROTECTION" == "y" || "$NEED_PROTECTION" == "Y" || "$NEED_PROTECTION" == "n" || "$NEED_PROTECTION" == "N" ]]; then
            break
        fi
        warn "Пожалуйста, введите только 'y' или 'n'"
    done

    while true; do
        question "Введите домен панели (например, panel.domain.com):"
        PANEL_DOMAIN="$REPLY"
        if [[ -n "$PANEL_DOMAIN" ]]; then
            break
        fi
        warn "Домен панели не может быть пустым. Пожалуйста, введите значение."
    done

    while true; do
        question "Введите домен подписок (например, sub.domain.com):"
        SUB_DOMAIN="$REPLY"
        if [[ -n "$SUB_DOMAIN" ]]; then
            break
        fi
        warn "Домен подписок не может быть пустым. Пожалуйста, введите значение."
    done

    question "Введите порт панели (по умолчанию 3000):"
    PANEL_PORT="$REPLY"
    PANEL_PORT=${PANEL_PORT:-3000}

    question "Введите порт подписок (по умолчанию 3010):"
    SUB_PORT="$REPLY"
    SUB_PORT=${SUB_PORT:-3010}

    if [ "$NEED_PROTECTION" = "y" ]; then
        while true; do
            question "Введите имя проекта:"
            PROJECT_NAME="$REPLY"
            if [[ -n "$PROJECT_NAME" ]]; then
                break
            fi
            warn "Имя проекта не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите описание страницы подписки:"
            PROJECT_DESCRIPTION="$REPLY"
            if [[ -n "$PROJECT_DESCRIPTION" ]]; then
                break
            fi
            warn "Описание проекта не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите путь доступа к панели (например, supersecretroute):"
            CUSTOM_LOGIN_ROUTE="$REPLY"
            if [[ -n "$CUSTOM_LOGIN_ROUTE" ]]; then
                break
            fi
            warn "Путь доступа к панели не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите логин администратора:"
            LOGIN_USERNAME="$REPLY"
            if [[ -n "$LOGIN_USERNAME" ]]; then
                break
            fi
            warn "Логин администратора не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите email администратора:"
            LOGIN_EMAIL="$REPLY"
            if [[ -n "$LOGIN_EMAIL" ]]; then
                break
            fi
            warn "Email администратора не может быть пустым. Пожалуйста, введите значение."
        done

        while true; do
            question "Введите пароль администратора (мин. 8 символов, хотя бы одна заглавная, строчная, цифра и спецсимвол):"
            LOGIN_PASSWORD="$REPLY"
            if [[ ${#LOGIN_PASSWORD} -lt 8 ]]; then
                warn "Пароль слишком короткий! Минимум 8 символов."
                continue
            fi
            if ! [[ "$LOGIN_PASSWORD" =~ [A-Z] ]]; then
                warn "Пароль должен содержать хотя бы одну заглавную букву (A-Z)."
                continue
            fi
            if ! [[ "$LOGIN_PASSWORD" =~ [a-z] ]]; then
                warn "Пароль должен содержать хотя бы одну строчную букву (a-z)."
                continue
            fi
            if ! [[ "$LOGIN_PASSWORD" =~ [0-9] ]]; then
                warn "Пароль должен содержать хотя бы одну цифру (0-9)."
                continue
            fi
            if ! [[ "$LOGIN_PASSWORD" =~ [^a-zA-Z0-9] ]]; then
                warn "Пароль должен содержать хотя бы один специальный символ (!, @, #, $, %, ^, &, *, -, +, =, ? и т.д.)."
                continue
            fi
            break
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
