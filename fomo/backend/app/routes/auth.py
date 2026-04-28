import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..db import get_db
from ..deps import get_user_id
from ..models import User, UserSession
from ..schemas import AccountLogin, AccountOut, AccountRegister, AuthOut
from ..security import hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=AuthOut, status_code=201)
def register_account(payload: AccountRegister, db: Session = Depends(get_db)):
    normalized_username = payload.username.strip().lower()
    if not normalized_username:
        raise HTTPException(status_code=400, detail="Username is required")

    existing_user = db.scalar(select(User).where(User.username == normalized_username))
    if existing_user:
        raise HTTPException(status_code=409, detail="Username is already in use")

    user = User(
        id=uuid.uuid4().hex,
        username=normalized_username,
        password_hash=hash_password(payload.password),
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Username is already in use")

    token = uuid.uuid4().hex
    db.add(UserSession(token=token, user_id=user.id))
    db.commit()

    return AuthOut(token=token, user_id=user.id, username=user.username)


@router.post("/login", response_model=AuthOut)
def login_account(payload: AccountLogin, db: Session = Depends(get_db)):
    normalized_username = payload.username.strip().lower()
    user = db.scalar(select(User).where(User.username == normalized_username))
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid username or password")

    token = uuid.uuid4().hex
    db.add(UserSession(token=token, user_id=user.id))
    db.commit()

    return AuthOut(token=token, user_id=user.id, username=user.username)


@router.get("/me", response_model=AccountOut)
def my_account(
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id),
):
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return AccountOut(id=user.id, username=user.username, created_at=user.created_at)
