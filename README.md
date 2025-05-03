# RemnaNode Setup Script

Скрипт для автоматической установки и настройки **RemnaNode** на вашем сервере.

## Что включает скрипт

Этот скрипт выполняет следующие действия:

- **Маскировочный сайт**: Устанавливает сайт для маскировки.
- **Caddy**: Устанавливает и настраивает веб-сервер Caddy.
- **Tblocker**: Устанавливает и настраивает Tblocker для дополнительной защиты от торрентов.
- **BBR**: Устанавливает BBR.
- **RemnaNode**: Устанавливает и настраивает саму ноду RemnaNode.

## Установка

Для установки выполните следующую команду:

```bash
bash -c 'curl -sL https://raw.githubusercontent.com/Capybara-z/RemnaNode/refs/heads/main/install_node.sh -o /tmp/install_node.sh && chmod +x /tmp/install_node.sh && sudo /tmp/install_node.sh'
