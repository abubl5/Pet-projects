import argparse

import requests

from smart_handbook.api_clients.wikipedia_client import WikipediaClient


def main():
    parser = argparse.ArgumentParser(
        description="Консольный справочник для получения определений из Wikipedia."
    )
    parser.add_argument("term", type=str, help="Термин для поиска определения.")
    parser.add_argument(
        "--lang",
        type=str,
        default="ru",
        choices=["ru", "en"],
        help="Язык поиска (ru - русский, en - английский). По умолчанию 'ru'.",
    )

    args = parser.parse_args()
    client = WikipediaClient()

    try:
        summary = client.get_summary(args.term, args.lang)
        if summary:
            print(summary)
        else:
            print(f"Определение по запросу '{args.term}' на языке '{args.lang}' не найдено.")
    except requests.exceptions.RequestException as e:
        print(f"Ошибка сети/сервиса: {e}")
    except ValueError as e:
        print(f"Ошибка обработки данных: {e}")
    except Exception as e:
        print(f"Произошла непредвиденная ошибка: {e}")


if __name__ == "__main__":
    main()
