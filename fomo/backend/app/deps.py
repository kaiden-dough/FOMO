from sqlalchemy import select
from sqlalchemy.orm import Session

from fastapi import Depends, Header, HTTPException

from .db import get_db
from .models import UserSession


def get_user_id(
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> str:
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization header")

    parts = authorization.split(" ", maxsplit=1)
    if len(parts) != 2 or parts[0].lower() != "bearer" or not parts[1].strip():
        raise HTTPException(status_code=401, detail="Invalid Authorization header")

    token = parts[1].strip()
    session = db.scalar(select(UserSession).where(UserSession.token == token))
    if not session:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return session.user_id
