from datetime import datetime

from pydantic import BaseModel, Field


class AccountRegister(BaseModel):
    username: str = Field(min_length=3, max_length=40)
    password: str = Field(min_length=8, max_length=128)


class AccountLogin(BaseModel):
    username: str = Field(min_length=3, max_length=40)
    password: str = Field(min_length=1, max_length=128)


class GoogleAuthIn(BaseModel):
    id_token: str | None = None
    access_token: str | None = None


class AuthOut(BaseModel):
    token: str
    user_id: str
    username: str


class AccountOut(BaseModel):
    id: str
    username: str
    created_at: datetime


class FriendOut(BaseModel):
    id: str
    username: str


class FriendsOut(BaseModel):
    following: list[FriendOut]
    followers: list[FriendOut]
    suggested: list[FriendOut]


class EventCreate(BaseModel):
    id: str = Field(min_length=1)
    title: str = Field(min_length=1)
    date: datetime
    location: str = Field(min_length=1)
    description: str = Field(min_length=1)
    latitude: float | None = None
    longitude: float | None = None


class EventOut(BaseModel):
    id: str
    title: str
    date: datetime
    location: str
    attending: int
    description: str
    latitude: float | None = None
    longitude: float | None = None
    is_rsvpd: bool = False
    poster_id: str | None = None
    poster_name: str | None = None


class EventsListOut(BaseModel):
    events: list[EventOut]
