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

    case $component in
        "panel")
            if [ -f "$path/docker-compose.yml" ] && (cd "$path" && docker compose ps -q | grep -q "remnawave") || [ -f "$env_file" ]; then
                info "Обнаружена установка Remnawave"
                while true; do
                    question "Переустановить Remnawave? (y/n):"
                    REINSTALL="$REPLY"
                    if [[ "$REINSTALL" == "y" || "$REINSTALL" == "Y" ]]; then
                        warn "Останавливаем и удаляем существующую установку..."
                        cd "$path" && docker compose down
                        docker rmi remnawave/panel:latest 2>/dev/null || true
                        docker rmi remnawave/redis:latest 2>/dev/null || true
                        docker rmi remnawave/postgres:latest 2>/dev/null || true
                        rm -f "$env_file"
                        rm -f "$path/docker-compose.yml"
                        REINSTALL_PANEL=true
                        break
                    elif [[ "$REINSTALL" == "n" || "$REINSTALL" == "N" ]]; then
                        info "Отказано в переустановке Remnawave"
                        REINSTALL_PANEL=false
                        break
                    else
                        warn "Пожалуйста, введите только 'y' или 'n'"
                    fi
                done
            else
                REINSTALL_PANEL=true
            fi
            ;;
        "subscription")
            if [ -f "$path/docker-compose.yml" ] && (cd "$path" && docker compose ps -q | grep -q "remnawave-subscription-page") || [ -f "$path/app-config.json" ]; then
                info "Обнаружена установка страницы подписок"
                while true; do
                    question "Переустановить страницу подписок? (y/n):"
                    REINSTALL="$REPLY"
                    if [[ "$REINSTALL" == "y" || "$REINSTALL" == "Y" ]]; then
                        warn "Останавливаем и удаляем существующую установку..."
                        cd "$path" && docker compose down
                        docker rmi remnawave/subscription-page:latest 2>/dev/null || true
                        rm -f "$path/app-config.json"
                        rm -f "$path/docker-compose.yml"
                        REINSTALL_SUBSCRIPTION=true
                        break
                    elif [[ "$REINSTALL" == "n" || "$REINSTALL" == "N" ]]; then
                        info "Отказано в переустановке страницы подписок"
                        REINSTALL_SUBSCRIPTION=false
                        break
                    else
                        warn "Пожалуйста, введите только 'y' или 'n'"
                    fi
                done
            else
                REINSTALL_SUBSCRIPTION=true
            fi
            ;;
        "caddy")
            if [ -f "$path/docker-compose.yml" ] || [ -f "$path/Caddyfile" ]; then
                info "Обнаружена установка Caddy"
                while true; do
                    question "Переустановить Caddy? (y/n):"
                    REINSTALL="$REPLY"
                    if [[ "$REINSTALL" == "y" || "$REINSTALL" == "Y" ]]; then
                        warn "Останавливаем и удаляем существующую установку..."
                        if [ -f "$path/docker-compose.yml" ]; then
                            cd "$path" && docker compose down
                        fi
                        if docker ps -a --format '{{.Names}}' | grep -q "remnawave-caddy\|caddy"; then
                            if [ "$NEED_PROTECTION" = "y" ]; then
                                docker rmi remnawave/caddy-with-auth:latest 2>/dev/null || true
                            else
                                docker rmi caddy:2.9 2>/dev/null || true
                            fi
                        fi
                        rm -f "$path/Caddyfile"
                        rm -f "$path/docker-compose.yml"
                        REINSTALL_CADDY=true
                        break
                    elif [[ "$REINSTALL" == "n" || "$REINSTALL" == "N" ]]; then
                        info "Отказано в переустановке Caddy"
                        REINSTALL_CADDY=false
                        break
                    else
                        warn "Пожалуйста, введите только 'y' или 'n'"
                    fi
                done
            else
                REINSTALL_CADDY=true
            fi
            ;;
    esac
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

    if [ "$REINSTALL_SUBSCRIPTION" = true ]; then
        info "Установка страницы подписок..."
        mkdir -p /opt/remnawave/subscription
        cd /opt/remnawave/subscription

        cp "/opt/remnasetup/data/app-config.json" app-config.json
        cp "/opt/remnasetup/data/docker/subscription-compose.yml" docker-compose.yml

        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" docker-compose.yml
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" docker-compose.yml
        sed -i "s|\$PROJECT_NAME|$PROJECT_NAME|g" docker-compose.yml
        sed -i "s|\$PROJECT_DESCRIPTION|$PROJECT_DESCRIPTION|g" docker-compose.yml

        docker compose up -d
    fi

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

        docker compose up -d
    fi
}

install_with_protection() {
    if [ "$REINSTALL_PANEL" = true ]; then
        info "Установка панели Remnawave с защитой..."
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

    if [ "$REINSTALL_SUBSCRIPTION" = true ]; then
        info "Установка страницы подписок с защитой..."
        mkdir -p /opt/remnawave/subscription
        cd /opt/remnawave/subscription

        cp "/opt/remnasetup/data/app-config.json" app-config.json
        cp "/opt/remnasetup/data/docker/subscription-protection-compose.yml" docker-compose.yml

        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" docker-compose.yml
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" docker-compose.yml
        sed -i "s|\$PROJECT_NAME|$PROJECT_NAME|g" docker-compose.yml
        sed -i "s|\$PROJECT_DESCRIPTION|$PROJECT_DESCRIPTION|g" docker-compose.yml

        docker compose up -d
    fi

    if [ "$REINSTALL_CADDY" = true ]; then
        info "Установка Caddy с защитой..."
        mkdir -p /opt/remnawave/caddy
        cd /opt/remnawave/caddy

        cp "/opt/remnasetup/data/caddy/caddyfile-protection" Caddyfile
        cp "/opt/remnasetup/data/docker/caddy-protection-compose.yml" docker-compose.yml

        sed -i "s|\$PANEL_PORT|$PANEL_PORT|g" Caddyfile
        sed -i "s|\$SUB_DOMAIN|$SUB_DOMAIN|g" Caddyfile
        sed -i "s|\$SUB_PORT|$SUB_PORT|g" Caddyfile

        sed -i "s|\$PANEL_DOMAIN|$PANEL_DOMAIN|g" docker-compose.yml
        sed -i "s|\$CUSTOM_LOGIN_ROUTE|$CUSTOM_LOGIN_ROUTE|g" docker-compose.yml
        sed -i "s|\$LOGIN_USERNAME|$LOGIN_USERNAME|g" docker-compose.yml
        sed -i "s|\$LOGIN_EMAIL|$LOGIN_EMAIL|g" docker-compose.yml
        sed -i "s|\$LOGIN_PASSWORD|$LOGIN_PASSWORD|g" docker-compose.yml

        docker compose up -d
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

    if [ "$REINSTALL_PANEL" = false ] && [ "$REINSTALL_SUBSCRIPTION" = false ] && [ "$REINSTALL_CADDY" = false ]; then
        info "Нет компонентов для установки"
        read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
        exit 0
    fi

    while true; do
        question "Требуется ли защита панели кастомным путем и защита подписок? (y/n):"
        NEED_PROTECTION="$REPLY"
        if [[ "$NEED_PROTECTION" == "y" || "$NEED_PROTECTION" == "Y" ]]; then
            break
        elif [[ "$NEED_PROTECTION" == "n" || "$NEED_PROTECTION" == "N" ]]; then
            break
        else
            warn "Пожалуйста, введите только 'y' или 'n'"
        fi
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

    while true; do
        question "Введите логин для метрик:"
        METRICS_USER="$REPLY"
        if [[ -n "$METRICS_USER" ]]; then
            break
        fi
        warn "Логин для метрик не может быть пустым. Пожалуйста, введите значение."
    done

    while true; do
        question "Введите пароль для метрик:"
        METRICS_PASS="$REPLY"
        if [[ -n "$METRICS_PASS" ]]; then
            break
        fi
        warn "Пароль для метрик не может быть пустым. Пожалуйста, введите значение."
    done

    while true; do
        question "Введите имя пользователя базы данных:"
        DB_USER="$REPLY"
        if [[ -n "$DB_USER" ]]; then
            break
        fi
        warn "Имя пользователя базы данных не может быть пустым. Пожалуйста, введите значение."
    done

    while true; do
        question "Введите пароль пользователя базы данных:"
        DB_PASSWORD="$REPLY"
        if [[ -n "$DB_PASSWORD" ]]; then
            break
        fi
        warn "Пароль пользователя базы данных не может быть пустым. Пожалуйста, введите значение."
    done

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

    if [ "$NEED_PROTECTION" = "y" ]; then
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
