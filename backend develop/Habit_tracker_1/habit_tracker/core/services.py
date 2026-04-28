"""Бизнес-логика для работы с привычками."""

from datetime import date, timedelta
from typing import Dict, List, Optional
from habit_tracker.core.models import Habit, HabitCreate, HabitUpdate
from habit_tracker.core.exceptions import (
    HabitNotFoundException,
    HabitAlreadyMarkedTodayException,
    HabitNameConflictException,
    InvalidInputException
)

# In-memory хранилище
TODAY = date(2025, 7, 12)  # Для детерминированности в тестах
habits_db: Dict[int, Habit] = {}
next_habit_id = 1


def _is_name_taken(name: str, exclude_id: Optional[int] = None) -> bool:
    return any(
        h.name.lower().strip() == name.lower().strip() and h.id != exclude_id
        for h in habits_db.values()
    )


def calculate_streak(marks: List[date]) -> int:
    '''Рассчитывает *текущий* streak по датам в `marks` относительно `TODAY`.'''
    if not marks:
        return 0
    marks_set = set(marks)
    streak = 0
    cur = TODAY
    while cur in marks_set:
        streak += 1
        cur -= timedelta(days=1)
    return streak


def calculate_max_streak(marks: List[date]) -> int:
    """Рассчитывает максимальный streak за всё время."""
    if not marks:
        return 0
    unique_sorted = sorted(set(marks))
    max_streak = 1
    current_streak = 1
    for i in range(1, len(unique_sorted)):
        if (unique_sorted[i] - unique_sorted[i - 1]).days == 1:
            current_streak += 1
            max_streak = max(max_streak, current_streak)
        else:
            current_streak = 1
    return max_streak


def calculate_habit_stats(habit: Habit) -> dict:
    """Рассчитывает статистику по привычке."""
    marks_dates = habit.marks
    total_marks = len(marks_dates)
    current_streak = calculate_streak(marks_dates)
    max_streak = calculate_max_streak(marks_dates)

    if not marks_dates:
        success_rate = 0.0
    else:
        first_mark = min(marks_dates)
        days_since_start = (TODAY - first_mark).days + 1
        success_rate = (total_marks / days_since_start) * 100 if days_since_start > 0 else 0.0
        success_rate = round(success_rate, 2)

    last_dates = sorted(marks_dates, reverse=True)[:5]

    return {
        "total_marks": total_marks,
        "current_streak": current_streak,
        "max_streak": max_streak,
        "success_rate": success_rate,
        "last_dates": last_dates,
    }


# === CRUD + Mark ===

def get_all_habits() -> List[Habit]:
    """Получить список всех привычек (для веб-статистики)."""
    return list(habits_db.values())


def get_habit_by_id(habit_id: int) -> Habit:
    """Возвращает привычку или выбрасывает исключение."""
    habit = habits_db.get(habit_id)
    if habit is None:
        raise HabitNotFoundException()
    return habit


def create_habit(habit_data: HabitCreate) -> Habit:
    """Создать новую привычку."""
    name = habit_data.name.strip()
    if not name:
        raise InvalidInputException(detail="Habit name cannot be empty.")
    if _is_name_taken(name):
        raise HabitNameConflictException()
    global next_habit_id
    habit = Habit(id=next_habit_id, name=name)
    habit.streak = 0
    habits_db[next_habit_id] = habit
    next_habit_id += 1
    return habit


def update_habit(habit_id: int, habit_data: HabitUpdate) -> Habit:
    """Обновить привычку."""
    habit = get_habit_by_id(habit_id)
    name = habit_data.name.strip()
    if not name:
        raise InvalidInputException(detail="Habit name cannot be empty.")
    if _is_name_taken(name, exclude_id=habit_id):
        raise HabitNameConflictException()
    habit.name = name
    return habit


def delete_habit(habit_id: int) -> None:
    """Удалить привычку."""
    habit = get_habit_by_id(habit_id)
    del habits_db[habit_id]


def mark_habit_completed(habit_id: int) -> Habit:
    """Отметить выполнение привычки за текущий день."""
    habit = get_habit_by_id(habit_id)
    if TODAY in habit.marks:
        raise HabitAlreadyMarkedTodayException()
    habit.marks.append(TODAY)
    habit.streak = calculate_streak(habit.marks)
    return habit


# === Вспомогательные функции для вьюх (оставлены для совместимости) ===

def get_all_habits_with_details() -> list[dict]:
    '''Возвращает список привычек с рассчитанным streak.'''
    result = []
    for habit in sorted(habits_db.values(), key=lambda h: h.id):
        habit.streak = calculate_streak(habit.marks)
        result.append({
            "id": habit.id,
            "name": habit.name,
            "marks": habit.marks,
            "streak": habit.streak,
        })
    return result


def get_habit_by_id_with_details(habit_id: int) -> dict:
    '''Возвращает одну привычку по `id` в виде словаря с рассчитанным `streak`.'''
    habit = get_habit_by_id(habit_id)
    habit.streak = calculate_streak(habit.marks)
    return {
        "id": habit.id,
        "name": habit.name,
        "marks": habit.marks,
        "streak": habit.streak,
    }


def is_habit_marked_today(habit_id: int) -> bool:
    '''Отвечает, отмечена ли привычка за `TODAY`.'''
    habit = habits_db.get(habit_id)
    if habit is None:
        return False
    return TODAY in habit.marks
