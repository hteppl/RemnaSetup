#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

update_panel() {
    info "Обновление ноды Remnanode..."
    cd /opt/remnanode || exit 1
    docker compose down
    docker compose pull
    docker compose up -d
}

main() {
    update_panel

    success "Обновление завершено!"
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    exit 0
}

main
