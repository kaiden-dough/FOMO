from datetime import datetime

from pydantic import BaseModel, Field


class AccountRegister(BaseModel):
    username: str = Field(min_length=3, max_length=40)
    password: str = Field(min_length=8, max_length=128)


class AccountLogin(BaseModel):
    username: str = Field(min_length=3, max_length=40)
    password: str = Field(min_length=1, max_length=128)


class AuthOut(BaseModel):
    token: str
    user_id: str
    username: str


class AccountOut(BaseModel):
    id: str
    username: str
    created_at: datetime


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
