"""Validate tokens with our configured Supabase project, never client claims."""
import requests
from fastapi import HTTPException

from .config import SUPABASE_PUBLISHABLE_KEY, SUPABASE_URL


def verify_google_session(access_token: str) -> dict:
    if not SUPABASE_URL.startswith("https://") or not SUPABASE_PUBLISHABLE_KEY:
        raise HTTPException(503, "Google sign-in is not configured")
    try:
        response = requests.get(
            f"{SUPABASE_URL}/auth/v1/user",
            headers={"apikey": SUPABASE_PUBLISHABLE_KEY,
                     "Authorization": f"Bearer {access_token}"},
            timeout=10,
            allow_redirects=False,
        )
        if response.status_code in {401, 403}:
            raise HTTPException(401, "Invalid or expired Google session")
        if response.status_code != 200:
            raise HTTPException(503, "Google sign-in is temporarily unavailable")
        user = response.json()
    except (requests.RequestException, ValueError):
        raise HTTPException(503, "Google sign-in is temporarily unavailable")
    identities = user.get("identities") or []
    if not user.get("id") or not user.get("email") or not user.get("email_confirmed_at"):
        raise HTTPException(401, "A verified email is required")
    if not any(identity.get("provider") == "google" for identity in identities):
        raise HTTPException(403, "Please sign in with Google")
    return user
