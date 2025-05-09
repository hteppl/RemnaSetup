#!/bin/bash

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_RED='\033[1;31m'

info() {
    echo -e "${BOLD_BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${BOLD_YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${BOLD_RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${BOLD_GREEN}[SUCCESS]${NC} $1"
}

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || exit 1

info "Скачивание RemnaSetup..."
curl -L https://github.com/Capybara-z/RemnaSetup/archive/refs/heads/main.zip -o remnasetup.zip

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

cd RemnaSetup-main || exit 1

chmod +x remnasetup.sh

success "Запуск RemnaSetup..."
./remnasetup.sh

cd - || exit 1
rm -rf "$TEMP_DIR" 
