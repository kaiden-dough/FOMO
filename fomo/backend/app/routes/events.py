from datetime import datetime

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from fastapi import APIRouter, Depends, HTTPException

from ..db import get_db
from ..deps import get_optional_user_id, get_user_id
from ..models import Event, Rsvp, User
from ..schemas import EventCreate, EventsListOut, EventOut

router = APIRouter(prefix="/events", tags=["events"])


@router.get("", response_model=EventsListOut)
def list_events(
    db: Session = Depends(get_db),
    user_id: str | None = Depends(get_optional_user_id),
):
    now = datetime.utcnow()
    events = db.scalars(select(Event).order_by(Event.date.asc())).all()
    active_events = [
        e for e in events if (e.end_time or e.date) >= now
    ]
    creator_ids = {e.creator_id for e in active_events if e.creator_id}
    creators = {
        u.id: u
        for u in db.scalars(select(User).where(User.id.in_(creator_ids))).all()
    } if creator_ids else {}

    rsvped_event_ids = (
        set(db.scalars(select(Rsvp.event_id).where(Rsvp.user_id == user_id)).all())
        if user_id
        else set()
    )

    return {
        "events": [
            EventOut(
                id=e.id,
                title=e.title,
                date=e.start_time or e.date,
                start_time=e.start_time or e.date,
                end_time=e.end_time or e.date,
                location=e.location,
                attending=e.attending,
                description=e.description,
                latitude=e.latitude,
                longitude=e.longitude,
                is_rsvpd=e.id in rsvped_event_ids,
                poster_id=e.creator_id,
                poster_name=creators[e.creator_id].username if e.creator_id and e.creator_id in creators else "unknown",
            )
            for e in active_events
        ]
    }


@router.post("", response_model=EventOut, status_code=201)
def create_event(
    payload: EventCreate,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id),
):
    current_user = db.get(User, user_id)
    if not current_user:
        raise HTTPException(status_code=404, detail="User not found")

    event = Event(
        id=payload.id,
        title=payload.title,
        start_time=payload.start_time,
        end_time=payload.end_time,
        date=payload.start_time,
        location=payload.location,
        attending=1,
        description=payload.description,
        latitude=payload.latitude,
        longitude=payload.longitude,
        creator_id=current_user.id,
    )
    db.add(event)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Event id already exists")

    rsvp = Rsvp(user_id=user_id, event_id=payload.id)
    db.add(rsvp)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()

    return EventOut(
        id=event.id,
        title=event.title,
        date=event.start_time or event.date,
        start_time=event.start_time or event.date,
        end_time=event.end_time or event.date,
        location=event.location,
        attending=event.attending,
        description=event.description,
        latitude=event.latitude,
        longitude=event.longitude,
        is_rsvpd=True,
        poster_id=current_user.id,
        poster_name=current_user.username,
    )


@router.post("/{event_id}/rsvp", status_code=204)
def rsvp_event(
    event_id: str,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id),
):
    event = db.get(Event, event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    db.add(Rsvp(user_id=user_id, event_id=event_id))
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        return

    event.attending += 1
    db.add(event)
    db.commit()


@router.delete("/{event_id}/rsvp", status_code=204)
def unrsvp_event(
    event_id: str,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id),
):
    event = db.get(Event, event_id)
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    rsvp = db.scalar(select(Rsvp).where(Rsvp.user_id == user_id, Rsvp.event_id == event_id))
    if not rsvp:
        return

    db.delete(rsvp)
    db.commit()

    event.attending = max(0, event.attending - 1)
    db.add(event)
    db.commit()
