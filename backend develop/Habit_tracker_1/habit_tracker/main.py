import os
import sys

import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles

if __package__ in (None, ""):
    sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from habit_tracker.api import habits_api
from habit_tracker.views import web
from habit_tracker.core.exceptions import (
    HabitNotFoundException,
    HabitAlreadyMarkedTodayException,
    HabitNameConflictException,
    InvalidInputException
)

app = FastAPI()

base_dir = os.path.dirname(__file__)
templates_dir = os.path.join(base_dir, "templates")
static_dir = os.path.join(base_dir, "static")
templates = Jinja2Templates(directory=templates_dir)

app.mount("/static", StaticFiles(directory=static_dir), name="static")
app.include_router(web.router, tags=["Web Interface"])
app.include_router(habits_api.router, prefix="/api/habits", tags=["Habits API"])


# === EXCEPTION HANDLERS ===
@app.exception_handler(HabitNotFoundException)
async def habit_not_found_exception_handler(request: Request, exc: HabitNotFoundException):
    if request.url.path.startswith("/api"):
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})
    return RedirectResponse(url=f"/?error={exc.detail}", status_code=303)


@app.exception_handler(HabitAlreadyMarkedTodayException)
async def habit_already_marked_today_exception_handler(request: Request, exc: HabitAlreadyMarkedTodayException):
    if request.url.path.startswith("/api"):
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})
    # Пытаемся получить habit_id из пути для редиректа на детальную страницу
    path = request.url.path
    import re
    match = re.search(r'/habit/(\d+)', path)
    if match:
        habit_id = match.group(1)
        return RedirectResponse(url=f"/habit/{habit_id}/?error={exc.detail}", status_code=303)
    return RedirectResponse(url=f"/?error={exc.detail}", status_code=303)


@app.exception_handler(HabitNameConflictException)
async def habit_name_conflict_exception_handler(request: Request, exc: HabitNameConflictException):
    if request.url.path.startswith("/api"):
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})
    return RedirectResponse(url=f"/?error={exc.detail}", status_code=303)


@app.exception_handler(InvalidInputException)
async def invalid_input_exception_handler(request: Request, exc: InvalidInputException):
    if request.url.path.startswith("/api"):
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})
    return RedirectResponse(url=f"/?error={exc.detail}", status_code=303)


if __name__ == "__main__":
    uvicorn.run("habit_tracker.main:app", host="127.0.0.1", port=8000, reload=False)
