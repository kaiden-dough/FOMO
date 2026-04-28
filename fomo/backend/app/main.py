from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .db import Base, engine
from .routes import auth, events, friends, me

app = FastAPI(title="FOMO Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)

app.include_router(events.router)
app.include_router(me.router)
app.include_router(auth.router)
app.include_router(friends.router)


@app.get("/health", tags=["health"])
def health():
    return {"ok": True}
