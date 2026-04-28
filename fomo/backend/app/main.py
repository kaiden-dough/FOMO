from fastapi import FastAPI

from .db import Base, engine
from .routes import auth, events, me

app = FastAPI(title="FOMO Backend")

Base.metadata.create_all(bind=engine)

app.include_router(events.router)
app.include_router(me.router)
app.include_router(auth.router)


@app.get("/health", tags=["health"])
def health():
    return {"ok": True}
