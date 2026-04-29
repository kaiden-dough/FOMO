from sqlalchemy import select
from sqlalchemy.orm import Session

from fastapi import Depends, Header, HTTPException

from .db import get_db
from .models import UserSession


def _read_bearer_token(authorization: str | None) -> str | None:
    if not authorization:
        return None
    parts = authorization.split(" ", maxsplit=1)
    if len(parts) != 2 or parts[0].lower() != "bearer" or not parts[1].strip():
        raise HTTPException(status_code=401, detail="Invalid Authorization header")
    return parts[1].strip()


def get_user_id(
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> str:
    token = _read_bearer_token(authorization)
    if not token:
        raise HTTPException(status_code=401, detail="Missing Authorization header")
    session = db.scalar(select(UserSession).where(UserSession.token == token))
    if not session:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return session.user_id


def get_optional_user_id(
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> str | None:
    token = _read_bearer_token(authorization)
    if not token:
        return None
    session = db.scalar(select(UserSession).where(UserSession.token == token))
    if not session:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return session.user_id
