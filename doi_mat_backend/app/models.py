# app/models.py
from pydantic import BaseModel
from typing import List, Optional

class BoundingBox(BaseModel):
    box: List[float]
    label: str
    score: float

class PredictionResponse(BaseModel):
    objects: List[BoundingBox]

class DescriptionResponse(BaseModel):
    description: str
    objects: List[str]

class QuizQuestion(BaseModel):
    question: str
    options: List[str]
    correct_answer_index: int

class QuizResponse(BaseModel):
    questions: List[QuizQuestion]