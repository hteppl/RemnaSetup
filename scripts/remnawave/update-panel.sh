#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

update_panel() {
    info "Обновление Remnawave..."
    cd /opt/remnawave
    docker compose down
    docker compose pull
    docker compose up -d
    success "Remnawave успешно обновлен!"
}

main() {
    update_panel
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    exit 0
}

main
