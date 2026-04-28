import requests
from telebot import types

from telegram_bot.handlers.command_handlers import _cut
from telegram_bot.state import get_user_state, update_user_state


def register_callback_handlers(bot):
    @bot.callback_query_handler(func=lambda call: call.data in {"show_full", "show_summary"})
    def handle_wiki_callback(call):
        bot.answer_callback_query(call.id)

        chat_id = call.message.chat.id
        message_id = call.message.message_id
        state = get_user_state(chat_id) or {}

        if not state:
            bot.send_message(chat_id, "Нет данных для отображения.")
            return

        if state.get("last_message_id") and state["last_message_id"] != message_id:
            return

        if call.data == "show_full":
            state["display_mode"] = "full"
            new_text = state.get("full_text") or "Полный текст недоступен."
        else:
            state["display_mode"] = "summary"
            new_text = state.get("summary_text") or "Краткое описание недоступно."

        update_user_state(chat_id, **state)

        markup = types.InlineKeyboardMarkup()
        if state["display_mode"] == "summary":
            markup.add(types.InlineKeyboardButton(text="Подробнее", callback_data="show_full"))
        else:
            markup.add(types.InlineKeyboardButton(text="Кратко", callback_data="show_summary"))

        if state.get("article_url"):
            markup.add(types.InlineKeyboardButton(text="Читать в Wikipedia", url=state["article_url"]))

        try:
            bot.edit_message_text(
                chat_id=chat_id,
                message_id=message_id,
                text=_cut(new_text),
                reply_markup=markup,
            )
        except requests.exceptions.RequestException:
            bot.send_message(chat_id, "Ошибка при обновлении сообщения.")
        except Exception:
            sent = bot.send_message(chat_id, _cut(new_text), reply_markup=markup)
            update_user_state(chat_id, last_message_id=sent.message_id)
