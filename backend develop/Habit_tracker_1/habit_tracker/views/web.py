from fastapi import APIRouter, Request, Form
from fastapi.responses import RedirectResponse
from fastapi.templating import Jinja2Templates
from habit_tracker.core import services
from habit_tracker.core.models import HabitCreate, HabitUpdate
from habit_tracker.core.exceptions import (
    HabitNotFoundException,
    HabitAlreadyMarkedTodayException,
    HabitNameConflictException,
    InvalidInputException
)
from fastapi.responses import HTMLResponse


router = APIRouter()
templates = Jinja2Templates(directory="habit_tracker/templates")


@router.get("/", name="main-page")
def main_page(request: Request):
    habits = services.get_all_habits_with_details()
    error = request.query_params.get("error")
    return templates.TemplateResponse(
        "index.html",
        {"request": request, "habits": habits, "error": error, "TODAY": services.TODAY}
    )


@router.get("/habit/{habit_id}", name="habit-detail")
def habit_detail(request: Request, habit_id: int):
    try:
        habit = services.get_habit_by_id_with_details(habit_id)
    except HabitNotFoundException:
        return RedirectResponse(url=f"/?error=Habit not found.", status_code=303)
    error = request.query_params.get("error")
    return templates.TemplateResponse(
        "habit_detail.html",
        {"request": request, "habit": habit, "error": error}
    )


@router.post("/habit/add", name="add_habit_from_form")
def add_habit(name: str = Form(...)):
    try:
        services.create_habit(HabitCreate(name=name))
    except (InvalidInputException, HabitNameConflictException) as e:
        return RedirectResponse(url=f"/?error={e.detail}", status_code=303)
    return RedirectResponse(url=router.url_path_for("main-page"), status_code=303)


@router.post("/habit/{habit_id}/mark", name="mark_habit_from_form")
def mark_habit(habit_id: int):
    try:
        services.mark_habit_completed(habit_id)
    except HabitAlreadyMarkedTodayException as e:
        return RedirectResponse(url=f"/habit/{habit_id}/?error={e.detail}", status_code=303)
    except HabitNotFoundException:
        return RedirectResponse(url=f"/?error=Habit not found.", status_code=303)
    return RedirectResponse(url=router.url_path_for("main-page"), status_code=303)


@router.post("/habit/{habit_id}/edit", name="edit_habit_from_form")
def edit_habit(habit_id: int, name: str = Form(...)):
    try:
        services.update_habit(habit_id, HabitUpdate(name=name))
    except (InvalidInputException, HabitNameConflictException) as e:
        return RedirectResponse(url=f"/habit/{habit_id}/?error={e.detail}", status_code=303)
    return RedirectResponse(
        url=router.url_path_for("habit-detail", habit_id=habit_id),
        status_code=303
    )


@router.post("/habit/{habit_id}/delete", name="delete_habit_from_form")
def delete_habit(habit_id: int):
    try:
        services.delete_habit(habit_id)
    except HabitNotFoundException:
        return RedirectResponse(url=f"/?error=Habit not found.", status_code=303)
    return RedirectResponse(url=router.url_path_for("main-page"), status_code=303)


# === НОВЫЙ маршрут: статистика ===
@router.get("/stats/", response_class=HTMLResponse, name="stats-page")
def get_stats_page(request: Request):
    habits = services.get_all_habits()
    stats_data = []
    for habit in habits:
        stats = services.calculate_habit_stats(habit)
        stats_data.append({
            "id": habit.id,
            "name": habit.name,
            **stats
        })
    error = request.query_params.get("error")
    return templates.TemplateResponse(
        "stats.html",
        {"request": request, "stats": stats_data, "error": error}
    )
