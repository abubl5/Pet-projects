from typing import Optional

import requests


class WikipediaClient:
    BASE_URL = "https://ru.wikipedia.org/w/api.php"
    HEADERS = {"User-Agent": "SmartHandbookBot/1.0 (contact: support@example.com)"}

    def _make_request(self, params: dict, url: Optional[str] = None) -> dict:
        if url is None:
            url = self.BASE_URL

        try:
            response = requests.get(url, params=params, headers=self.HEADERS, timeout=10)
            response.raise_for_status()
            data = response.json()
            if not isinstance(data, dict):
                raise ValueError("Некорректный формат JSON от Wikipedia.")
            return data
        except ValueError as e:
            raise ValueError(f"Ошибка обработки JSON: {e}") from e
        except (requests.ConnectionError, requests.Timeout) as e:
            raise requests.ConnectionError("Ошибка сети: не удалось подключиться к Wikipedia.") from e
        except requests.RequestException as e:
            raise requests.RequestException(f"Ошибка HTTP-запроса: {e}") from e

    def get_summary(self, term: str, lang: str = "ru", chars: int = 500) -> Optional[str]:
        url = f"https://{lang}.wikipedia.org/w/api.php"
        params = {
            "action": "query",
            "format": "json",
            "prop": "extracts",
            "exintro": True,
            "explaintext": True,
            "exchars": chars,
            "redirects": 1,
            "titles": term,
        }

        try:
            data = self._make_request(params, url)
            pages = data.get("query", {}).get("pages", {})
            if not pages:
                return None

            page_id, page = next(iter(pages.items()))
            if page_id == "-1" or "missing" in page:
                return None

            extract = page.get("extract")
            if not extract or not isinstance(extract, str):
                return None

            return extract.strip()
        except requests.RequestException:
            return None
        except (KeyError, AttributeError, StopIteration, TypeError):
            return None
        except Exception:
            return None

    def get_full_article(self, term: str, lang: str = "ru") -> Optional[str]:
        url = f"https://{lang}.wikipedia.org/w/api.php"
        params = {
            "action": "query",
            "format": "json",
            "prop": "extracts",
            "explaintext": True,
            "redirects": 1,
            "titles": term,
        }

        try:
            data = self._make_request(params, url)
            pages = data.get("query", {}).get("pages", {})
            if not pages:
                return None

            page_id, page = next(iter(pages.items()))
            if page_id == "-1" or "missing" in page:
                return None

            extract = page.get("extract")
            return extract.strip() if extract else None
        except requests.RequestException:
            return None
        except (KeyError, AttributeError, StopIteration, TypeError) as e:
            raise ValueError(f"Некорректный формат ответа от Wikipedia: {e}") from e
        except Exception as e:
            raise Exception(f"Неизвестная ошибка: {e}") from e

    def get_article_url(self, term: str, lang: str = "ru") -> Optional[str]:
        url = f"https://{lang}.wikipedia.org/w/api.php"
        params = {
            "action": "query",
            "format": "json",
            "prop": "info",
            "inprop": "url",
            "redirects": 1,
            "titles": term,
        }

        try:
            data = self._make_request(params, url)
            pages = data.get("query", {}).get("pages", {})
            if not pages:
                return None

            page_id, page = next(iter(pages.items()))
            if page_id == "-1" or "missing" in page:
                return None

            return page.get("fullurl")
        except requests.RequestException:
            return None
        except (KeyError, AttributeError, StopIteration, TypeError) as e:
            raise ValueError(f"Некорректный формат ответа от Wikipedia: {e}") from e
        except Exception as e:
            raise Exception(f"Неизвестная ошибка: {e}") from e
