from datetime import datetime, timedelta

from pydantic import BaseModel, Field, model_validator


class AccountRegister(BaseModel):
    username: str = Field(min_length=3, max_length=40)
    password: str = Field(min_length=8, max_length=128)


class AccountLogin(BaseModel):
    username: str = Field(min_length=3, max_length=40)
    password: str = Field(min_length=1, max_length=128)


class GoogleAuthIn(BaseModel):
    id_token: str | None = None
    access_token: str | None = None


class SupabaseAuthIn(BaseModel):
    access_token: str = Field(min_length=1, max_length=16384)
    link_account: bool = False


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
    start_time: datetime | None = None
    end_time: datetime | None = None
    # Legacy compatibility for older clients.
    date: datetime | None = None
    location: str = Field(min_length=1)
    description: str = Field(min_length=1)
    latitude: float | None = None
    longitude: float | None = None

    @model_validator(mode="after")
    def validate_times(self) -> "EventCreate":
        start = self.start_time or self.date
        if start is None:
            raise ValueError("start_time is required")
        self.start_time = start
        if self.end_time is None:
            self.end_time = start + timedelta(hours=2)
        if self.end_time < self.start_time:
            raise ValueError("end_time must be after start_time")
        return self


class EventOut(BaseModel):
    id: str
    title: str
    date: datetime
    start_time: datetime
    end_time: datetime
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
