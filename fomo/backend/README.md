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

## Auth (temporary)

Send a `X-User-Id` header on requests.

## Endpoints

- `GET /health`
- `GET /events`
- `POST /events`
- `POST /events/{event_id}/rsvp`
- `DELETE /events/{event_id}/rsvp`
- `GET /me/rsvps`
