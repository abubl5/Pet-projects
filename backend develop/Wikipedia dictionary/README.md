# Smart Handbook

Небольшой Python-проект с двумя интерфейсами для получения краткой справочной информации из Wikipedia:

- `smart_handbook` — CLI-утилита для поиска определений по термину.
- `telegram_bot` — Telegram-бот с кнопками переключения между кратким и полным описанием статьи.

Проект подходит как учебный pet-project для резюме: здесь есть работа с внешним API, обработка ошибок, разделение на модули и два пользовательских сценария запуска.

## Что умеет

- искать краткое описание термина в русской или английской Wikipedia;
- получать полную статью и ссылку на оригинальный материал;
- показывать результат в CLI;
- отдавать результат в Telegram-боте с inline-кнопками.

## Стек

- Python 3
- `requests`
- `pyTelegramBotAPI`
- `python-dotenv`

## Быстрый запуск

1. Установить зависимости:

```bash
python3 -m pip install -r requirements.txt
```

2. Запустить CLI:

```bash
python3 -m smart_handbook.cli.main "Интеграл"
python3 -m smart_handbook.cli.main "Euler" --lang en
```

3. Запустить Telegram-бота:

```bash
cp .env.example .env
```

Заполнить `TG_BOT_TOKEN`, затем выполнить:

```bash
python3 -m telegram_bot.bot
```

## Структура

- `smart_handbook/api_clients/wikipedia_client.py` — клиент Wikipedia API
- `smart_handbook/cli/main.py` — консольная точка входа
- `telegram_bot/bot.py` — запуск Telegram-бота
- `telegram_bot/handlers/` — обработчики команд и callback-кнопок
- `telegram_bot/state.py` — хранение состояния пользователя

