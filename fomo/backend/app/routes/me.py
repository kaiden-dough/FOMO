from sqlalchemy import select
from sqlalchemy.orm import Session

from fastapi import APIRouter, Depends

from ..db import get_db
from ..deps import get_user_id
from ..models import Event, Rsvp, User
from ..schemas import EventsListOut, EventOut

router = APIRouter(prefix="/me", tags=["me"])


@router.get("/rsvps", response_model=EventsListOut)
def my_rsvps(
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id),
):
    events = db.scalars(
        select(Event)
        .join(Rsvp, Rsvp.event_id == Event.id)
        .where(Rsvp.user_id == user_id)
        .order_by(Event.date.asc())
    ).all()
    creator_ids = {e.creator_id for e in events if e.creator_id}
    creators = {
        u.id: u
        for u in db.scalars(select(User).where(User.id.in_(creator_ids))).all()
    } if creator_ids else {}

    return {
        "events": [
            EventOut(
                id=e.id,
                title=e.title,
                date=e.date,
                location=e.location,
                attending=e.attending,
                description=e.description,
                latitude=e.latitude,
                longitude=e.longitude,
                is_rsvpd=True,
                poster_id=e.creator_id,
                poster_name=creators[e.creator_id].username if e.creator_id and e.creator_id in creators else "unknown",
            )
            for e in events
        ]
    }
