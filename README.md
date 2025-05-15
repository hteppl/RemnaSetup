# RemnaSetup 🛠️

<div align="center">

![RemnaSetup](https://img.shields.io/badge/RemnaSetup-2.4-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-orange)

**Универсальный скрипт для автоматической установки, настройки и обновления инфраструктуры Remnawave и Remnanode**

[![Stars](https://img.shields.io/github/stars/Capybara-z/RemnaSetup?style=social)](https://github.com/Capybara-z/RemnaSetup)
[![Forks](https://img.shields.io/github/forks/Capybara-z/RemnaSetup?style=social)](https://github.com/Capybara-z/RemnaSetup)

</div>

---

## 🚀 Возможности

<div align="center">

### 🔥 Основные компоненты

</div>

<table>
<tr>
<td width="50%" align="center">

### 🎯 Remnawave
- Установка и настройка панели управления
- Установка страницы подписок
- Интеграция с Caddy для проксирования запросов
- Защита панели и подпсиок
- Автоматическое обновление компонентов

</td>
<td width="50%" align="center">

### 🌐 Remnanode
- Установка и настройка ноды
- Интеграция с Caddy для self-styl
- Настройка Tblocker для защиты от торрентов
- Оптимизация сети через BBR
- Интеграция с WARP
- Автоматическое обновление компонентов

</td>
</tr>
</table>

<div align="center">

---

### 🗄️ Бэкап/Восстановление Remnawave

- 💾 Создание резервной копии Remnawave
- ♻️ Восстановление Remnawave из архива
- 📂 Архивы хранятся в /opt/backups
- 📋 Типы бэкапов: ручной, автоматический, с отправкой в Telegram
- 🕒 Автоматический бэкап с настраиваемым расписанием

---

</div>

### ⚡ Дополнительные возможности
- **Модульная структура** с разделением на отдельные скрипты
- **Интерактивное меню** с возможностью выбора компонентов
- **Автоматическое обновление** всех компонентов
- **Проверка существующих установок** перед установкой
- **Возможность переустановки** с сохранением данных
- **Улучшенная обработка ошибок** и логирование
- **Бэкап и восстановление Remnawave** через отдельное меню

---

## 📋 Опции меню

<div align="center">

### 🎮 Интерактивное меню

</div>

<table>
<tr>
<td width="50%" align="center">

### 1️⃣ Remnawave
- 📦 Полная установка (Remnawave + Страница подписок + Caddy)
- 🚀 Установка Remnawave
- 📄 Установка Страницы подписок
- ⚙️ Установка Caddy
- 🔄 Обновление (Remnawave + Страницы подписок)
- 🔄 Обновление Remnawave
- 🔄 Обновление Страницы подписок

</td>
<td width="50%" align="center">

### 2️⃣ Remnanode
- 📦 Полная установка (Remnanode + Caddy + Tblocker + BBR + WARP)
- 🚀 Установка Remnanode
- ⚙️ Установка Caddy + self-styl
- 🛡️ Установка Tblocker
- ⚡ Установка BBR
- 🌐 Установка WARP
- 🔄 Обновление Remnanode

</td>
</tr>
</table>

<div align="center">

---

### 3️⃣ Бэкап/Восстановление Remnawave

- 💾 Создание резервной копии Remnawave
- ♻️ Восстановление Remnawave из архива
- 📂 Архивы хранятся в /opt/backups
- 🕒 Автоматический бэкап с настраиваемым расписанием
- 📤 Отправка бэкапов в Telegram бота
- 🗑️ Автоматическая очистка старых бэкапов
- 🛡️ Все действия через удобное меню

---

</div>

---

## 🖥️ Быстрый старт

- Вариант 1
```bash
bash <(curl -fsSL raw.githubusercontent.com/Capybara-z/RemnaSetup/refs/heads/main/install.sh)
```
- Вариант 2
```bash
curl -fsSL https://raw.githubusercontent.com/Capybara-z/RemnaSetup/refs/heads/main/install.sh -o install.sh && chmod +x install.sh && sudo bash ./install.sh
```

---

## 💡 Как это работает

<div align="center">

### 🔄 Процесс установки

</div>

1. **🎯 Выбор опции** в главном меню
2. **📝 Ввод данных**:
   - 🌐 Домены для панели и подписок
   - 🔌 Порты для сервисов
   - 🔑 Учетные данные для базы данных
   - 📊 Настройки метрик
   - 🤖 Токены для Tblocker
   - 🌐 Параметры WARP
3. **🗄️ Бэкап и восстановление**
4. **⚡ Автоматизация**:
   - ✅ Проверка существующих установок
   - 📦 Установка/обновление компонентов
   - ⚙️ Настройка конфигураций
   - 🚀 Запуск сервисов
   - 📋 Просмотр логов

---

## 🛡️ Безопасность

<div align="center">

### 🔒 Меры безопасности

</div>

- 🔐 Использование sudo только для установки
- 🔑 Ручной ввод чувствительных данных
- 🗑️ Удаление временных файлов
- 📝 Защищенное хранение конфигураций
- 🔒 Проверка прав доступа
- 🛡️ Валидация вводимых данных

---

## ⭐️ Поддержка проекта

<div align="center">

Если скрипт был полезен — поставьте ⭐️ на [GitHub](https://github.com/Capybara-z/RemnaSetup)!

[![Star](https://img.shields.io/github/stars/Capybara-z/RemnaSetup?style=social)](https://github.com/Capybara-z/RemnaSetup)

### 📱 Контакты
 Telegram: [@KaTTuBaRa](https://t.me/KaTTuBaRa)

</div>

---

## 📄 Лицензия

MIT

---

<div align="center">

**RemnaSetup** — ваш универсальный помощник для быстрого старта и поддержки инфраструктуры Remnawave и RemnaNode! 🚀

</div>