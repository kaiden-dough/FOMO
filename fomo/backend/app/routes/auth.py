import uuid

from fastapi import APIRouter, Depends, HTTPException
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
import requests
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..db import get_db
from ..deps import get_user_id
from ..config import GOOGLE_CLIENT_ID
from ..models import User, UserSession
from ..schemas import AccountLogin, AccountOut, AccountRegister, AuthOut, GoogleAuthIn
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
    if not user or not user.password_hash or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid username or password")

    token = uuid.uuid4().hex
    db.add(UserSession(token=token, user_id=user.id))
    db.commit()

    return AuthOut(token=token, user_id=user.id, username=user.username)


@router.post("/google", response_model=AuthOut)
def login_with_google(payload: GoogleAuthIn, db: Session = Depends(get_db)):
    if not payload.id_token and not payload.access_token:
        raise HTTPException(status_code=400, detail="Google token is required")

    token_info = None
    if payload.id_token:
        try:
            token_info = google_id_token.verify_oauth2_token(
                payload.id_token,
                google_requests.Request(),
                GOOGLE_CLIENT_ID or None,
            )
        except Exception:
            token_info = None

    if token_info is None and payload.access_token:
        userinfo_res = requests.get(
            "https://www.googleapis.com/oauth2/v3/userinfo",
            headers={"Authorization": f"Bearer {payload.access_token}"},
            timeout=10,
        )
        if userinfo_res.status_code >= 400:
            raise HTTPException(status_code=401, detail="Invalid Google access token")
        token_info = userinfo_res.json()

    if token_info is None:
        raise HTTPException(status_code=401, detail="Invalid Google token")

    google_sub = token_info.get("sub")
    email = token_info.get("email")
    if not google_sub or not email:
        raise HTTPException(status_code=400, detail="Google account info missing")

    username = email.strip().lower()
    user = db.scalar(select(User).where(User.google_sub == google_sub))
    if not user:
        user = db.scalar(select(User).where(User.username == username))
        if user:
            user.google_sub = google_sub
            db.add(user)
        else:
            user = User(
                id=uuid.uuid4().hex,
                username=username,
                password_hash=None,
                google_sub=google_sub,
            )
            db.add(user)
        db.commit()

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
