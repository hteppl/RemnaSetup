#!/bin/bash

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || exit 1

echo "Скачивание RemnaSetup..."
curl -L https://github.com/Capybara-z/RemnaSetup/archive/refs/heads/dev.zip -o remnasetup.zip

if ! command -v unzip &> /dev/null; then
    echo "Установка unzip..."
    if command -v apt-get &> /dev/null; then
        echo "Обновление списка пакетов..."
        sudo apt update -y && sudo apt install -y unzip
    elif command -v yum &> /dev/null; then
        sudo yum install -y unzip
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y unzip
    else
        echo "Не удалось установить unzip. Пожалуйста, установите его вручную."
        exit 1
    fi
fi

echo "Распаковка файлов..."
unzip -q remnasetup.zip

sudo mkdir -p /opt/remnasetup

echo "Установка RemnaSetup в /opt/remnasetup..."
sudo cp -r RemnaSetup-dev/* /opt/remnasetup/

echo "Установка прав..."
sudo chown -R $USER:$USER /opt/remnasetup
sudo chmod -R 755 /opt/remnasetup
sudo chmod +x /opt/remnasetup/remnasetup.sh
sudo chmod +x /opt/remnasetup/scripts/common/*.sh
sudo chmod +x /opt/remnasetup/scripts/remnawave/*.sh
sudo chmod +x /opt/remnasetup/scripts/remnanode/*.sh

cd /opt/remnasetup || exit 1

echo "Запуск RemnaSetup..."
bash /opt/remnasetup/remnasetup.sh

rm -rf "$TEMP_DIR" 
