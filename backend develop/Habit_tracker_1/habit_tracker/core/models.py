"""Модели данных для привычек."""

from datetime import date
from typing import List
from pydantic import BaseModel, validator


class Habit:
    """Внутренняя модель привычки для хранения в памяти."""
    id: int
    name: str
    marks: List[date]
    streak: int
    def __init__(self, id: int, name: str):
        self.id = id
        self.name = name
        self.marks = []
        self.streak: int = 0

class HabitCreate(BaseModel):
    """Модель для создания привычки."""
    name: str

    @validator('name')
    def name_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Habit name cannot be empty.')
        return v


class HabitBase(BaseModel):
    id: int
    name: str

class HabitUpdate(BaseModel):
    name: str

    @validator('name')
    def name_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Habit name cannot be empty.')
        return v


class HabitResponse(HabitBase):
    """Модель ответа после создания привычки."""
    marks: list[date]
    streak: int


class HabitMarkResponse(BaseModel):
    """Ответ после отметки привычки как выполненной."""
    id: int
    name: str
    last_marked_at: date
    streak: int


class HabitListResponse(BaseModel):
    """Модель списка привычек."""
    id: int
    name: str
    marks: List[date]
    streak: int

# --- НОВАЯ модель статистики ---
class HabitStatsResponse(BaseModel):
    id: int
    name: str
    total_marks: int
    current_streak: int
    max_streak: int
    success_rate: float
    last_dates: List[date]

    class Config:
        json_encoders = {
            date: lambda v: v.isoformat()
        }