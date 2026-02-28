from pydantic import BaseModel
from datetime import datetime


class TaskCreate(BaseModel):
    title: str


class TaskUpdate(BaseModel):
    completed: bool


class TaskResponse(BaseModel):
    id: int
    title: str
    completed: bool
    created_at: datetime

    class Config:
        from_attributes = True