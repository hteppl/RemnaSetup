#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

update_all() {
    info "Обновление всех компонентов..."
    
    cd /opt/remnawave
    docker compose down
    docker compose pull
    docker compose up -d

    cd /opt/remnawave/subscription
    docker compose down
    docker compose pull
    docker compose up -d
    
    success "Все компоненты успешно обновлены!"
}

main() {
    update_all
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    exit 0
}

main
