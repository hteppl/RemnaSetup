#!/bin/bash

source "$(dirname "$0")/../../scripts/common/colors.sh"
source "$(dirname "$0")/../../scripts/common/functions.sh"

check_docker() {
    if command -v docker >/dev/null 2>&1; then
        info "Docker уже установлен, пропускаем установку."
        return 0
    else
        return 1
    fi
}

install_docker() {
    info "Установка Docker..."
    sudo curl -fsSL https://get.docker.com | sh || {
        error "Ошибка: Не удалось установить Docker."
        exit 1
    }
    success "Docker успешно установлен!"
}

check_remnanode() {
    if sudo docker ps -q --filter "name=remnanode" | grep -q .; then
        info "Remnanode уже установлен"
        question "Хотите скорректировать настройки Remnanode? (y/n): "
        read -r REINSTALL
        
        if [[ "$REINSTALL" == "y" || "$REINSTALL" == "Y" ]]; then
            return 0
        else
            info "Remnanode уже установлен"
            read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
            "$(dirname "$0")/../../scripts/remnanode/menu.sh"
            exit 0
        fi
    fi
    return 1
}

install_remnanode() {
    info "Установка Remnanode..."
    sudo chmod -R 777 /opt
    mkdir -p /opt/remnanode
    sudo chown $USER:$USER /opt/remnanode
    cd /opt/remnanode

    echo "APP_PORT=$APP_PORT" > .env
    echo "$SSL_CERT_FULL" >> .env

    if [[ "$USE_TBLOCKER" == "y" || "$USE_TBLOCKER" == "Y" ]]; then
        cp "$(dirname "$0")/../../data/docker/node-tblocker-compose.yml" docker-compose.yml
    else
        cp "$(dirname "$0")/../../data/docker/node-compose.yml" docker-compose.yml
    fi

    sudo docker compose up -d || {
        error "Ошибка: Не удалось запустить Remnanode. Убедитесь, что Docker настроен корректно."
        exit 1
    }
    success "Remnanode успешно установлен!"
}

main() {
    if ! check_docker; then
        install_docker
    fi

    if check_remnanode; then
        cd /opt/remnanode
        sudo docker compose down
    fi

    while true; do
        question "Введите APP_PORT (по умолчанию 3001): "
        read -r APP_PORT
        APP_PORT=${APP_PORT:-3001}
        if [[ "$APP_PORT" =~ ^[0-9]+$ ]]; then
            break
        fi
        warn "Порт должен быть числом."
    done

    while true; do
        question "Введите SSL_CERT (можно получить при добавлении ноды в панели): "
        read -r SSL_CERT_FULL
        if [[ -n "$SSL_CERT_FULL" ]]; then
            break
        fi
        warn "SSL_CERT не может быть пустым. Пожалуйста, введите значение."
    done

    question "Будет ли использоваться Tblocker? (y/n): "
    read -r USE_TBLOCKER

    install_remnanode

    success "Установка завершена!"
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    "$(dirname "$0")/../../scripts/remnanode/menu.sh"
}

main 