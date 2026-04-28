# FOMO Backend

## Setup

1. Create a virtualenv
2. Install deps

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

3. Configure env

```bash
cp .env.example .env
```

## Run

```bash
uvicorn app.main:app --reload --port 8000
```

## Auth

- Email/password:
  - `POST /auth/register`
  - `POST /auth/login`
- Google sign-in:
  - `POST /auth/google` with `{ "id_token": "<google-id-token>" }`
- Protected endpoints use:
  - `Authorization: Bearer <token>`

## Endpoints

- `GET /health`
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/google`
- `GET /auth/me`
- `GET /events`
- `POST /events`
- `POST /events/{event_id}/rsvp`
- `DELETE /events/{event_id}/rsvp`
- `GET /me/rsvps`
- `GET /friends`
- `POST /friends/{target_user_id}/follow`
- `DELETE /friends/{target_user_id}/follow`
