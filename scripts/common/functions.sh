#!/bin/bash

. "$(dirname "$0")/colors.sh"

info() {
    echo -e "${BOLD_CYAN}[INFO]${RESET} $1"
}

warn() {
    echo -e "${BOLD_YELLOW}[WARN]${RESET} $1"
}

error() {
    echo -e "${BOLD_RED}[ERROR]${RESET} $1"
}

success() {
    echo -e "${BOLD_GREEN}[SUCCESS]${RESET} $1"
}

menu() {
    echo -e "${BOLD_MAGENTA}$1${RESET}"
}

question() {
    echo -e "${BOLD_CYAN}$1${RESET}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_root() {
    if [ "$(id -u)" != "0" ]; then
        error "This script must be run as root"
        exit 1
    fi
}

check_directory() {
    if [ ! -d "$1" ]; then
        error "Directory $1 does not exist"
        exit 1
    fi
}

check_file() {
    if [ ! -f "$1" ]; then
        error "File $1 does not exist"
        exit 1
    fi
}

create_directory() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

backup_file() {
    if [ -f "$1" ]; then
        cp "$1" "$1.bak"
    fi
}

restore_file() {
    if [ -f "$1.bak" ]; then
        mv "$1.bak" "$1"
    fi
}
