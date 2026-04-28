"""API роуты для управления привычками."""
from typing import List
from fastapi import APIRouter, status
from habit_tracker.core import services
from habit_tracker.core.models import (
    HabitUpdate,
    HabitCreate,
    HabitResponse,
    HabitMarkResponse,
    HabitListResponse,
    HabitStatsResponse
)

router = APIRouter()


@router.post("/", response_model=HabitResponse, status_code=status.HTTP_201_CREATED)
def create_habit(habit: HabitCreate):
    """Создать новую привычку."""
    new_habit = services.create_habit(habit)
    return HabitResponse(
        id=new_habit.id,
        name=new_habit.name,
        marks=new_habit.marks,
        streak=new_habit.streak
    )


@router.post("/{habit_id}/mark", response_model=HabitMarkResponse)
def mark_habit(habit_id: int):
    """Отметить выполнение привычки за текущий день."""
    habit = services.mark_habit_completed(habit_id)
    last_date = habit.marks[-1]
    return HabitMarkResponse(
        id=habit.id,
        name=habit.name,
        last_marked_at=last_date,
        streak=habit.streak
    )


@router.get("/", response_model=List[HabitListResponse])
def get_all_habits():
    """Получить список всех привычек."""
    habits = services.get_all_habits()
    return [
        HabitListResponse(id=h.id, name=h.name, marks=h.marks, streak=h.streak)
        for h in habits
    ]


@router.get("/{habit_id}", response_model=HabitResponse)
def get_habit(habit_id: int):
    """Получить одну привычку по ID."""
    habit = services.get_habit_by_id(habit_id)
    return HabitResponse(
        id=habit.id,
        name=habit.name,
        marks=habit.marks,
        streak=habit.streak
    )


@router.get("/{habit_id}/stats", response_model=HabitStatsResponse)
def get_habit_stats(habit_id: int):
    """Получить статистику по привычке."""
    habit = services.get_habit_by_id(habit_id)
    stats = services.calculate_habit_stats(habit)
    return HabitStatsResponse(
        id=habit.id,
        name=habit.name,
        total_marks=stats["total_marks"],
        current_streak=stats["current_streak"],
        max_streak=stats["max_streak"],
        success_rate=stats["success_rate"],
        last_dates=stats["last_dates"]
    )


@router.delete("/{habit_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_habit_api(habit_id: int):
    """Удалить привычку."""
    services.delete_habit(habit_id)
    return  # 204 — No Content


@router.put("/{habit_id}", response_model=HabitResponse)
def update_habit_api(habit_id: int, habit_update: HabitUpdate):
    """Обновить привычку."""
    habit = services.update_habit(habit_id, habit_update)
    return HabitResponse(
        id=habit.id,
        name=habit.name,
        marks=habit.marks,
        streak=habit.streak
    )
