#!/bin/bash

source "/opt/remnasetup/scripts/common/colors.sh"
source "/opt/remnasetup/scripts/common/functions.sh"

update_subscription() {
    info "Обновление Subscription..."
    cd /opt/remnawave/subscription || exit 1
    docker compose down
    docker compose pull
    docker compose up -d
    success "Subscription успешно обновлен!"
}

main() {
    update_subscription
    read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    exit 0
}

main
