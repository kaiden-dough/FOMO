from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import and_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..db import get_db
from ..deps import get_user_id
from ..models import Follow, User
from ..schemas import FriendOut, FriendsOut

router = APIRouter(prefix="/friends", tags=["friends"])


@router.get("", response_model=FriendsOut)
def list_friends(
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id),
):
    following_rows = db.execute(
        select(User).join(Follow, Follow.followed_id == User.id).where(Follow.follower_id == user_id)
    ).scalars().all()

    followers_rows = db.execute(
        select(User).join(Follow, Follow.follower_id == User.id).where(Follow.followed_id == user_id)
    ).scalars().all()

    followed_ids = {u.id for u in following_rows}
    suggested_query = select(User).where(User.id != user_id)
    if followed_ids:
        suggested_query = suggested_query.where(User.id.notin_(followed_ids))
    suggested_rows = db.scalars(suggested_query).all()

    return FriendsOut(
        following=[FriendOut(id=u.id, username=u.username) for u in following_rows],
        followers=[FriendOut(id=u.id, username=u.username) for u in followers_rows],
        suggested=[FriendOut(id=u.id, username=u.username) for u in suggested_rows],
    )


@router.post("/{target_user_id}/follow", status_code=204)
def follow_user(
    target_user_id: str,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id),
):
    if target_user_id == user_id:
        raise HTTPException(status_code=400, detail="Cannot follow yourself")
    if not db.get(User, target_user_id):
        raise HTTPException(status_code=404, detail="User not found")

    db.add(Follow(follower_id=user_id, followed_id=target_user_id))
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        return


@router.delete("/{target_user_id}/follow", status_code=204)
def unfollow_user(
    target_user_id: str,
    db: Session = Depends(get_db),
    user_id: str = Depends(get_user_id),
):
    follow = db.scalar(
        select(Follow).where(
            and_(Follow.follower_id == user_id, Follow.followed_id == target_user_id)
        )
    )
    if not follow:
        return
    db.delete(follow)
    db.commit()
