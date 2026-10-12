import uuid

import requests
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..db import get_db
from ..deps import get_user_id
from ..config import AUTH_MODE, DEPLOYMENT_COLOR, GOOGLE_CLIENT_ID, SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY
from ..models import AuthIdentity, User, UserSession
from ..schemas import AccountLogin, AccountOut, AccountRegister, AuthOut, GoogleAuthIn, SupabaseAuthIn
from ..security import hash_password, verify_password
from ..supabase_auth import verify_google_session

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=AuthOut, status_code=201)
def register_account(payload: AccountRegister, db: Session = Depends(get_db)):
    if AUTH_MODE == "google":
        raise HTTPException(403, "Please continue with Google")
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
    if AUTH_MODE == "google":
        raise HTTPException(403, "Please continue with Google")
    normalized_username = payload.username.strip().lower()
    user = db.scalar(select(User).where(User.username == normalized_username))
    if not user or not user.password_hash or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid username or password")

    token = uuid.uuid4().hex
    db.add(UserSession(token=token, user_id=user.id))
    db.commit()

    return AuthOut(token=token, user_id=user.id, username=user.username)


@router.get("/config")
def auth_config():
    return {
        "mode": AUTH_MODE,
        "password_enabled": AUTH_MODE != "google",
        "google_enabled": AUTH_MODE != "password" and bool(SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY),
        "deployment_color": DEPLOYMENT_COLOR,
    }


@router.post("/google", response_model=AuthOut)
def legacy_google_login(payload: GoogleAuthIn, db: Session = Depends(get_db)):
    # Retain the previous client flow on blue/hybrid until the Supabase cutover.
    if AUTH_MODE == "google":
        raise HTTPException(410, "Update FOMO to use Google sign-in through Supabase")
    if not GOOGLE_CLIENT_ID:
        raise HTTPException(503, "Legacy Google sign-in is not configured")
    try:
        if payload.id_token:
            claims = google_id_token.verify_oauth2_token(
                payload.id_token, google_requests.Request(), GOOGLE_CLIENT_ID,
            )
        elif payload.access_token:
            # Old Flutter web clients return access tokens. Validate audience first.
            response = requests.get("https://oauth2.googleapis.com/tokeninfo",
                                    params={"access_token": payload.access_token}, timeout=10,
                                    allow_redirects=False)
            if response.status_code != 200:
                raise HTTPException(401, "Invalid Google token")
            claims = response.json()
            if claims.get("aud") != GOOGLE_CLIENT_ID:
                raise HTTPException(401, "Invalid Google token audience")
        else:
            raise HTTPException(400, "Google token is required")
    except (ValueError, requests.RequestException):
        raise HTTPException(401, "Invalid Google token")
    if not claims.get("sub") or not claims.get("email") or claims.get("email_verified") not in (True, "true"):
        raise HTTPException(401, "A verified Google email is required")
    user = db.scalar(select(User).where(User.google_sub == claims["sub"]))
    if user is None:
        username = claims["email"].strip().lower()
        if db.scalar(select(User).where(User.username == username)):
            raise HTTPException(409, "Log in to your existing account and connect Google")
        user = User(id=uuid.uuid4().hex, username=username, google_sub=claims["sub"], password_hash=None)
        db.add(user)
    token = uuid.uuid4().hex
    try:
        db.flush()
        db.add(UserSession(token=token, user_id=user.id))
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Account changed during sign-in. Please try again")
    return AuthOut(token=token, user_id=user.id, username=user.username)


@router.post("/supabase", response_model=AuthOut)
def login_with_supabase(
    payload: SupabaseAuthIn,
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
):
    if AUTH_MODE == "password":
        raise HTTPException(403, "Google sign-in is not enabled")
    claims = verify_google_session(payload.access_token)
    subject = claims["id"]
    identity = db.scalar(select(AuthIdentity).where(
        AuthIdentity.provider == "supabase", AuthIdentity.subject == subject,
    ))
    if payload.link_account:
        current_user_id = get_user_id(authorization=authorization, db=db)
        user = db.get(User, current_user_id)
        if identity and identity.user_id != current_user_id:
            raise HTTPException(409, "This Google account is already connected to another account")
        existing = db.scalar(select(AuthIdentity).where(
            AuthIdentity.provider == "supabase", AuthIdentity.user_id == current_user_id,
        ))
        if existing and existing.subject != subject:
            raise HTTPException(409, "Your account is already connected to another Google account")
    elif identity:
        user = db.get(User, identity.user_id)
    else:
        username = claims["email"].strip().lower()
        user = db.scalar(select(User).where(User.username == username))
        if user:
            raise HTTPException(409, "Log in to your existing account first, then connect Google in Your Account")
        # Preserve accounts created by the previous Google flow, using Google's stable subject.
        google_subjects = [i.get("identity_data", {}).get("sub") for i in claims.get("identities", [])
                           if i.get("provider") == "google"]
        if any(db.scalar(select(User).where(User.google_sub == sub)) for sub in google_subjects if sub):
            raise HTTPException(409, "Sign in to your existing FOMO account and connect Google before switching")
        user = User(id=uuid.uuid4().hex, username=username, password_hash=None)
        db.add(user)
    if user is None:
        raise HTTPException(401, "Account no longer exists")
    token = uuid.uuid4().hex
    try:
        db.flush()
        if not identity:
            db.add(AuthIdentity(id=uuid.uuid4().hex, provider="supabase", subject=subject, user_id=user.id))
        db.add(UserSession(token=token, user_id=user.id))
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Account changed during sign-in. Please try again")
    return AuthOut(token=token, user_id=user.id, username=user.username)


@router.post("/logout", status_code=204)
def logout(authorization: str | None = Header(default=None), db: Session = Depends(get_db)):
    get_user_id(authorization=authorization, db=db)
    token = authorization.split(" ", 1)[1].strip()
    session = db.get(UserSession, token)
    db.delete(session)
    db.commit()


@router.get("/me", response_model=AccountOut)
def my_account(
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id),
):
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return AccountOut(id=user.id, username=user.username, created_at=user.created_at)
