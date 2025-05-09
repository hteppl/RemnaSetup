#!/bin/bash

source "$(dirname "$0")/scripts/common/colors.sh"
source "$(dirname "$0")/scripts/common/functions.sh"

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
  echo -e "${CYAN}Меню Remnawave:${RESET}"
  echo -e "${BLUE}1. Полная установка (Remnawave + Страница подписок + Caddy)${RESET}"
  echo -e "${BLUE}2. Установка Remnawave${RESET}"
  echo -e "${BLUE}3. Установка Страницы подписок${RESET}"
  echo -e "${BLUE}4. Установка Caddy${RESET}"
  echo -e "${BLUE}5. Обновление (Remnawave + Страницы подписок)${RESET}"
  echo -e "${BLUE}6. Обновление Remnawave${RESET}"
  echo -e "${BLUE}7. Обновление Страницы подписок${RESET}"
  echo -e "${BLUE}8. Назад${RESET}"
  echo
  question "Введите номер опции (1-8): "
  read REMNAWAVE_OPTION < /dev/tty
  echo
}

display_remnanode_menu() {
  clear
  print_header
  echo -e "${CYAN}Меню Remnanode:${RESET}"
  echo -e "${BLUE}1. Полная установка (Remnanode + Caddy + Tblocker + BBR + WARP)${RESET}"
  echo -e "${BLUE}2. Только Remnanode${RESET}"
  echo -e "${BLUE}3. Только Caddy + self-style${RESET}"
  echo -e "${BLUE}4. Только Tblocker${RESET}"
  echo -e "${BLUE}5. Только BBR${RESET}"
  echo -e "${BLUE}6. Установить WARP${RESET}"
  echo -e "${BLUE}7. Обновить Remnanode${RESET}"
  echo -e "${BLUE}8. Назад${RESET}"
  echo
  question "Введите номер опции (1-8): "
  read REMNANODE_OPTION < /dev/tty
  echo
}

display_main_menu() {
    clear
    print_header
    echo -e "${CYAN}Главное меню:${RESET}"
    echo -e "${BLUE}1. Установка/обновление Remnawave${RESET}"
    echo -e "${BLUE}2. Установка/обновление Remnanode${RESET}"
    echo -e "${RED}0. Выход${RESET}"
    echo
    question "Введите номер опции (0-2): "
    read MAIN_OPTION < /dev/tty
    echo
}

main() {
while true; do
  display_main_menu
  case $MAIN_OPTION in
    1)
      while true; do
        display_remnawave_menu
        case $REMNAWAVE_OPTION in
                        1) source "$(dirname "$0")/scripts/remnawave/install-full.sh" ;;
                        2) source "$(dirname "$0")/scripts/remnawave/install-panel.sh" ;;
                        3) source "$(dirname "$0")/scripts/remnawave/install-subscription.sh" ;;
                        4) source "$(dirname "$0")/scripts/remnawave/install-caddy.sh" ;;
                        5) source "$(dirname "$0")/scripts/remnawave/update-full.sh" ;;
                        6) source "$(dirname "$0")/scripts/remnawave/update-panel.sh" ;;
                        7) source "$(dirname "$0")/scripts/remnawave/update-subscription.sh" ;;
                        8) break ;;
                        *) warn "Неверный выбор. Попробуйте снова." ;;
        esac
      done
      ;;
    2)
      while true; do
        display_remnanode_menu
        case $REMNANODE_OPTION in
                        1) source "$(dirname "$0")/scripts/remnanode/install-full.sh" ;;
                        2) source "$(dirname "$0")/scripts/remnanode/install-panel.sh" ;;
                        3) source "$(dirname "$0")/scripts/remnanode/install-caddy.sh" ;;
                        4) source "$(dirname "$0")/scripts/remnanode/install-tblocker.sh" ;;
                        5) source "$(dirname "$0")/scripts/remnanode/install-bbr.sh" ;;
                        6) source "$(dirname "$0")/scripts/remnanode/install-warp.sh" ;;
                        7) source "$(dirname "$0")/scripts/remnanode/update.sh" ;;
                        8) break ;;
                        *) warn "Неверный выбор. Попробуйте снова." ;;
        esac
      done
      ;;
    0)
                info "Выход из программы..."
      exit 0
      ;;
    *)
                warn "Неверный выбор. Попробуйте снова."
      ;;
  esac
done
}

main 
