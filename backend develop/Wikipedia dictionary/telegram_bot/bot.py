import os

import telebot
from dotenv import load_dotenv

from telegram_bot.handlers.callback_handlers import register_callback_handlers
from telegram_bot.handlers.command_handlers import register_handlers


def main() -> None:
    load_dotenv()
    token = os.getenv("TG_BOT_TOKEN")
    if not token or token == "your_telegram_bot_token_here":
        print("Переменная окружения TG_BOT_TOKEN не задана. Бот не запущен.")
        return

    try:
        bot = telebot.TeleBot(token)
        register_handlers(bot)
        register_callback_handlers(bot)
        print("Бот запущен. Ожидание команд...")
        bot.infinity_polling()
    except telebot.apihelper.ApiException:
        print("Ошибка: недействительный токен Telegram API!")
    except Exception as e:
        print(f"Ошибка при запуске бота: {e}")


if __name__ == "__main__":
    main()
