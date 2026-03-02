import string
import random
from fastapi import FastAPI, Depends, HTTPException
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from database import SessionLocal, engine
from models import Base, URL

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Simple URL Shortener")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def generate_code(length=6):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))


@app.post("/shorten")
def shorten_url(original_url: str, db: Session = Depends(get_db)):
    short_code = generate_code()

    url = URL(original_url=original_url, short_code=short_code)
    db.add(url)
    db.commit()
    db.refresh(url)

    return {
        "short_url": f"http://localhost:8000/{short_code}"
    }


@app.get("/{short_code}")
def redirect(short_code: str, db: Session = Depends(get_db)):
    url = db.query(URL).filter(URL.short_code == short_code).first()

    if not url:
        raise HTTPException(status_code=404, detail="URL not found")

    url.clicks += 1
    db.commit()

    return RedirectResponse(url.original_url)


@app.get("/stats/{short_code}")
def stats(short_code: str, db: Session = Depends(get_db)):
    url = db.query(URL).filter(URL.short_code == short_code).first()

    if not url:
        raise HTTPException(status_code=404, detail="URL not found")

    return {
        "original_url": url.original_url,
        "clicks": url.clicks
    }