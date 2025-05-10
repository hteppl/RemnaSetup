#!/bin/bash

SCRIPT_DIR="/opt/remnasetup"

. /opt/remnasetup/scripts/common/colors.sh
. /opt/remnasetup/scripts/common/functions.sh

menu() {
    echo -e "${BOLD_MAGENTA}$1${RESET}"
}

question() {
    echo -e "${BOLD_CYAN}$1${RESET}"
}

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

print_header() {
    clear
    echo -e "${MAGENTA}────────────────────────────────────────────────────────────${RESET}"
    echo -e "\033[1;32m"
    echo -e "┌───────────────────────────────────────────────────────────────────┐"
    echo -e "│  ██████╗ █████╗ ██████╗ ██╗   ██╗██████╗  █████╗ ██████╗  █████╗  │"
    echo -e "│ ██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗ │"
    echo -e "│ ██║     ███████║██████╔╝ ╚████╔╝ ██████╔╝███████║██████╔╝███████║ │"
    echo -e "│ ██║     ██╔══██║██╔═══╝   ╚██╔╝  ██╔══██╗██╔══██║██╔══██╗██╔══██║ │"
    echo -e "│ ╚██████╗██║  ██║██║        ██║   ██████╔╝██║  ██║██║  ██║██║  ██║ │"
    echo -e "│  ╚═════╝╚═╝  ╚═╝╚═╝        ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ │"
    echo -e "└───────────────────────────────────────────────────────────────────┘"
    echo -e "\033[0m"
    echo -e "${MAGENTA}────────────────────────────────────────────────────────────${RESET}"
    echo -e "${GREEN}RemnaSetup by capybara${RESET}"
    echo -e "${CYAN}Проект: https://github.com/Capybara-z/RemnaSetup${RESET}"
    echo -e "${YELLOW}Контакты: @KaTTuBaRa${RESET}"
    echo -e "${CYAN}Версия: 2.0${RESET}"
    echo
    echo -e "${MAGENTA}────────────────────────────────────────────────────────────${RESET}"
    echo -e "${YELLOW}Сделано при поддержке проекта:"
    echo -e "${MAGENTA}────────────────────────────────────────────────────────────${RESET}"
    echo -e "\033[38;5;208m"
    echo -e "┌────────────────────────────────────────────────────────────┐"
    echo -e "│███████╗ ██████╗ ██╗      ██████╗ ██████╗  ██████╗ ████████╗│"
    echo -e "│██╔════╝██╔═══██╗██║     ██╔═══██╗██╔══██╗██╔═══██╗╚══██╔══╝│"
    echo -e "│███████╗██║   ██║██║     ██║   ██║██████╔╝██║   ██║   ██║   │"
    echo -e "│╚════██║██║   ██║██║     ██║   ██║██╔══██╗██║   ██║   ██║   │"
    echo -e "│███████║╚██████╔╝███████╗╚██████╔╝██████╔╝╚██████╔╝   ██║   │"
    echo -e "│╚══════╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝  ╚═════╝    ╚═╝   │"
    echo -e "└────────────────────────────────────────────────────────────┘"
    echo -e "\033[0m"
    echo -e "${MAGENTA}────────────────────────────────────────────────────────────${RESET}"
    echo -e "${CYAN}GitHub SoloBot: https://github.com/Vladless/Solo_bot${RESET}"
    echo -e "${YELLOW}Контакты: @Vladless${RESET}"
    echo -e "${MAGENTA}────────────────────────────────────────────────────────────${RESET}"
    echo
}

display_remnawave_menu() {
  clear
  print_header
  menu "Меню Remnawave:"
  echo -e "${BLUE}1. Полная установка (Remnawave + Страница подписок + Caddy)${RESET}"
  echo -e "${BLUE}2. Установка Remnawave${RESET}"
  echo -e "${BLUE}3. Установка Страницы подписок${RESET}"
  echo -e "${BLUE}4. Установка Caddy${RESET}"
  echo -e "${BLUE}5. Обновление (Remnawave + Страницы подписок)${RESET}"
  echo -e "${BLUE}6. Обновление Remnawave${RESET}"
  echo -e "${BLUE}7. Обновление Страницы подписок${RESET}"
  echo -e "${BLUE}8. Назад${RESET}"
  echo
  read -p "$(echo -e "${BOLD_CYAN}Выберите пункт меню (1-8):${RESET}") " REMNAWAVE_OPTION
  echo
}

display_remnanode_menu() {
  clear
  print_header
  menu "Меню Remnanode:"
  echo -e "${BLUE}1. Полная установка (Remnanode + Caddy + Tblocker + BBR + WARP)${RESET}"
  echo -e "${BLUE}2. Только Remnanode${RESET}"
  echo -e "${BLUE}3. Только Caddy + self-style${RESET}"
  echo -e "${BLUE}4. Только Tblocker${RESET}"
  echo -e "${BLUE}5. Только BBR${RESET}"
  echo -e "${BLUE}6. Установить WARP${RESET}"
  echo -e "${BLUE}7. Обновить Remnanode${RESET}"
  echo -e "${BLUE}8. Назад${RESET}"
  echo
  read -p "$(echo -e "${BOLD_CYAN}Выберите пункт меню (1-8):${RESET}") " REMNANODE_OPTION
  echo
}

display_main_menu() {
    clear
    print_header
    menu "Главное меню:"
    echo -e "${BLUE}1. Установка/обновление Remnawave${RESET}"
    echo -e "${BLUE}2. Установка/обновление Remnanode${RESET}"
    echo -e "${RED}0. Выход${RESET}"
    echo
    read -p "$(echo -e "${BOLD_CYAN}Выберите пункт меню (0-2):${RESET}") " MAIN_OPTION
    echo
}

run_script() {
    local script="$1"
    if [ -f "$script" ]; then
        bash "$script"
        local result=$?
        if [ $result -ne 0 ]; then
            warn "Скрипт завершился с ошибкой"
            read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
        fi
    else
        error "Скрипт не найден: $script"
        read -n 1 -s -r -p "Нажмите любую клавишу для возврата в меню..."
    fi
}

main() {
while true; do
  display_main_menu
  case $MAIN_OPTION in
    1)
      while true; do
        display_remnawave_menu
        case $REMNAWAVE_OPTION in
                        1) run_script "${SCRIPT_DIR}/scripts/remnawave/install-full.sh" ;;
                        2) run_script "${SCRIPT_DIR}/scripts/remnawave/install-panel.sh" ;;
                        3) run_script "${SCRIPT_DIR}/scripts/remnawave/install-subscription.sh" ;;
                        4) run_script "${SCRIPT_DIR}/scripts/remnawave/install-caddy.sh" ;;
                        5) run_script "${SCRIPT_DIR}/scripts/remnawave/update-full.sh" ;;
                        6) run_script "${SCRIPT_DIR}/scripts/remnawave/update-panel.sh" ;;
                        7) run_script "${SCRIPT_DIR}/scripts/remnawave/update-subscription.sh" ;;
                        8) break ;;
                        *) warn "Неверный выбор. Попробуйте снова." ;;
        esac
      done
      ;;
    2)
      while true; do
        display_remnanode_menu
        case $REMNANODE_OPTION in
                        1) run_script "${SCRIPT_DIR}/scripts/remnanode/install-full.sh" ;;
                        2) run_script "${SCRIPT_DIR}/scripts/remnanode/install-panel.sh" ;;
                        3) run_script "${SCRIPT_DIR}/scripts/remnanode/install-caddy.sh" ;;
                        4) run_script "${SCRIPT_DIR}/scripts/remnanode/install-tblocker.sh" ;;
                        5) run_script "${SCRIPT_DIR}/scripts/remnanode/install-bbr.sh" ;;
                        6) run_script "${SCRIPT_DIR}/scripts/remnanode/install-warp.sh" ;;
                        7) run_script "${SCRIPT_DIR}/scripts/remnanode/update-panel.sh" ;;
                        8) break ;;
                        *) warn "Неверный выбор. Попробуйте снова." ;;
        esac
      done
      ;;
    0)
                info "Выход из программы..."
                echo -e "${RESET}"
                exit 0
      ;;
    *)
                warn "Неверный выбор. Попробуйте снова."
      ;;
  esac
done
}

main 