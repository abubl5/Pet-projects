user_states = {}


def get_user_state(chat_id: int) -> dict:
    if chat_id is None or not isinstance(chat_id, int):
        return {}

    if chat_id not in user_states:
        user_states[chat_id] = {
            "last_term": None,
            "display_mode": "summary",
            "summary_text": None,
            "full_text": None,
            "article_url": None,
            "last_message_id": None,
        }

    return user_states[chat_id]


def update_user_state(chat_id: int, **kwargs) -> None:
    if chat_id is None or not isinstance(chat_id, int):
        return

    state = get_user_state(chat_id)
    if not state:
        return

    for key, value in kwargs.items():
        if value is not None:
            state[key] = value

    user_states[chat_id] = state


def clear_user_state(chat_id: int) -> None:
    if chat_id is not None and isinstance(chat_id, int):
        user_states.pop(chat_id, None)
