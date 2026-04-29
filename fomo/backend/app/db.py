from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from .config import DATABASE_URL

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(DATABASE_URL, connect_args=connect_args)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def ensure_event_time_columns():
    inspector = inspect(engine)
    if "events" not in inspector.get_table_names():
        return

    column_names = {c["name"] for c in inspector.get_columns("events")}
    missing = []
    if "start_time" not in column_names:
        missing.append("start_time")
    if "end_time" not in column_names:
        missing.append("end_time")
    if not missing:
        return

    time_type = "DATETIME" if engine.dialect.name == "sqlite" else "TIMESTAMP"
    with engine.begin() as conn:
        for name in missing:
            conn.execute(text(f"ALTER TABLE events ADD COLUMN {name} {time_type}"))
        conn.execute(text("UPDATE events SET start_time = date WHERE start_time IS NULL"))
        conn.execute(text("UPDATE events SET end_time = date WHERE end_time IS NULL"))
