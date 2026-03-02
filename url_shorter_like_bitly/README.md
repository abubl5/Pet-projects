URL Shortener API (FastAPI)


URL Shortener is a REST API service for creating short links and tracking their usage.
Built to practice working with FastAPI, SQLAlchemy, and SQLite.

```markdown
Features:
    Create a short URL from an original link
    Redirect to the original URL using a short code
    Track number of clicks
    Retrieve statistics for each short link
    Automatic Swagger documentation
```

```markdown
Tech Stack:
    Python 3.11
    FastAPI
    SQLAlchemy
    SQLite
    Uvicorn
```

```markdown
How It Works:
    Send a URL to the /shorten endpoint
    The service generates a unique short code
```