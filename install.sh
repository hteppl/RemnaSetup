#!/bin/bash

source "$(dirname "$0")/scripts/common/functions.sh"

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || exit 1

info "Скачивание RemnaSetup..."
curl -L https://github.com/Capybara-z/RemnaSetup/archive/refs/heads/dev.zip -o remnasetup.zip

if ! command -v unzip &> /dev/null; then
    warn "Установка unzip..."
    if command -v apt-get &> /dev/null; then
        info "Обновление списка пакетов..."
        sudo apt update -y && sudo apt install -y unzip
    elif command -v yum &> /dev/null; then
        sudo yum install -y unzip
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y unzip
    else
        error "Не удалось установить unzip. Пожалуйста, установите его вручную."
        exit 1
    fi
fi

info "Распаковка файлов..."
unzip -q remnasetup.zip

sudo mkdir -p /opt/remnasetup

info "Установка RemnaSetup в /opt/remnasetup..."
sudo cp -r RemnaSetup-dev/* /opt/remnasetup/

sudo chown -R $USER:$USER /opt/remnasetup
sudo chmod +x /opt/remnasetup/remnasetup.sh

cd /opt/remnasetup || exit 1

success "Запуск RemnaSetup..."
./remnasetup.sh

rm -rf "$TEMP_DIR" 
