from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import CORS_ORIGINS
from .db import Base, engine, ensure_event_time_columns
from .routes import auth, events, friends, me

app = FastAPI(title="FOMO Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)
ensure_event_time_columns()

app.include_router(events.router)
app.include_router(me.router)
app.include_router(auth.router)
app.include_router(friends.router)


@app.get("/health", tags=["health"])
def health():
    return {"ok": True}
