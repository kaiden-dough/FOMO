from fastapi import FastAPI, HTTPException
from sqlalchemy import select, text
from sqlalchemy.exc import SQLAlchemyError
from fastapi.middleware.cors import CORSMiddleware

from .config import AUTH_MODE, CORS_ORIGINS, DEPLOYMENT_COLOR, SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY
from .db import Base, engine, ensure_event_time_columns
from .models import AuthIdentity
from .routes import auth, events, friends, me

app = FastAPI(title="FOMO Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine, tables=[
    table for table in Base.metadata.sorted_tables if table.name != "auth_identities"
])
ensure_event_time_columns()

app.include_router(events.router)
app.include_router(me.router)
app.include_router(auth.router)
app.include_router(friends.router)


@app.get("/health", tags=["health"])
def health():
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
            if AUTH_MODE != "password":
                connection.execute(select(AuthIdentity.id).limit(1))
    except SQLAlchemyError:
        raise HTTPException(503, "Database or auth migration is not ready")
    if AUTH_MODE != "password" and (not SUPABASE_URL.startswith("https://") or not SUPABASE_PUBLISHABLE_KEY):
        raise HTTPException(503, "Supabase Auth is not configured")
    return {"ok": True, "color": DEPLOYMENT_COLOR, "auth_mode": AUTH_MODE}
