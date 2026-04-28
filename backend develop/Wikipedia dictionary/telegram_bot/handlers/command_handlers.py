import requests
import telebot

from smart_handbook.api_clients.wikipedia_client import WikipediaClient
from telegram_bot.state import get_user_state, update_user_state

wikipedia_client = WikipediaClient()
MAX_LEN = 3900


def _cut(text: str | None) -> str:
    if not text:
        return ""
    return text if len(text) <= MAX_LEN else text[:MAX_LEN] + "…"


def _keyboard(chat_id: int) -> telebot.types.InlineKeyboardMarkup:
    from telebot import types

    state = get_user_state(chat_id)
    markup = types.InlineKeyboardMarkup()

    if state["display_mode"] == "summary":
        toggle_text = "Подробнее"
        toggle_data = "show_full"
    else:
        toggle_text = "Кратко"
        toggle_data = "show_summary"

    markup.add(types.InlineKeyboardButton(toggle_text, callback_data=toggle_data))

    if state.get("article_url"):
        markup.add(types.InlineKeyboardButton("Читать в Wikipedia", url=state["article_url"]))

    return markup


def register_handlers(bot):
    @bot.message_handler(commands=["start"])
    def start_command(message):
        bot.send_message(
            message.chat.id,
            "Привет! Я Умный Справочник. Чтобы получить определение, используйте команду /wiki <термин>. Например: /wiki Интеграл",
        )

    @bot.message_handler(commands=["help"])
    def help_command(message):
        bot.send_message(
            message.chat.id,
            "Я могу найти краткое определение по любому термину из Wikipedia. Просто используйте команду /wiki <термин>.\nПример: /wiki Эйлер",
        )

    @bot.message_handler(commands=["wiki"])
    def wiki_command(message):
        term = message.text[6:].strip()
        if len(term) == 0:
            bot.send_message(
                message.chat.id,
                "Пожалуйста, укажите термин для поиска.\nНапример: /wiki Интеграл",
            )
            return

        try:
            summary = wikipedia_client.get_summary(term, lang="ru")
            page = wikipedia_client.get_article_url(term, lang="ru")
            full_text = wikipedia_client.get_full_article(term)

            if summary is None:
                bot.send_message(message.chat.id, f"Описание термина - {term} не найдено")
                return

            update_user_state(
                message.chat.id,
                last_term=term,
                display_mode="summary",
                summary_text=summary,
                full_text=full_text,
                article_url=page,
                last_message_id=None,
            )

            sent = bot.send_message(
                message.chat.id,
                _cut(summary),
                reply_markup=_keyboard(message.chat.id),
            )
            update_user_state(message.chat.id, last_message_id=sent.message_id)
        except requests.exceptions.RequestException:
            bot.send_message(message.chat.id, "Ошибка при обращении к сервису. Попробуйте позже.")
        except ValueError:
            bot.send_message(message.chat.id, "Ошибка при обращении к сервису.")
        except Exception as e:
            bot.send_message(message.chat.id, f"Ошибка: {type(e).__name__} — {e}")

    @bot.message_handler(func=lambda message: message.text.startswith("/"))
    def unknown_command(message):
        bot.send_message(message.chat.id, "Неизвестная команда. Используйте /wiki <термин>.")
