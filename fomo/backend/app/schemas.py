from datetime import datetime

from pydantic import BaseModel, Field


class EventCreate(BaseModel):
    id: str = Field(min_length=1)
    title: str = Field(min_length=1)
    date: datetime
    location: str = Field(min_length=1)
    description: str = Field(min_length=1)


class EventOut(BaseModel):
    id: str
    title: str
    date: datetime
    location: str
    attending: int
    description: str
    is_rsvpd: bool = False


class EventsListOut(BaseModel):
    events: list[EventOut]
