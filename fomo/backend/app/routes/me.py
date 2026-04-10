from sqlalchemy import select
from sqlalchemy.orm import Session

from fastapi import APIRouter, Depends

from ..db import get_db
from ..deps import get_user_id
from ..models import Event, Rsvp
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

    return {
        "events": [
            EventOut(
                id=e.id,
                title=e.title,
                date=e.date,
                location=e.location,
                attending=e.attending,
                description=e.description,
                is_rsvpd=True,
            )
            for e in events
        ]
    }
