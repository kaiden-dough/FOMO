# FOMO Backend

Install `requirements.txt`, copy `.env.example` to `.env`, and run:

```sh
uvicorn app.main:app --reload --port 8000
```

## Authentication

- `GET /auth/config`: runtime login options for the frontend.
- `POST /auth/register` and `/auth/login`: existing username/password sessions.
- `POST /auth/google`: existing direct Google clients, retained on blue/hybrid with mandatory audience and verified-email checks. Retired in Google-only mode.
- `POST /auth/supabase`: exchange `{ "access_token": "<Supabase access token>" }` for a FOMO session. The backend checks the token with this project's `/auth/v1/user` endpoint, requires a Google identity and verified email, and stores the immutable Supabase user ID in `auth_identities`.
- Existing account linking: set `link_account: true` and supply the existing FOMO bearer token. Email matching never links accounts automatically.
- `POST /auth/logout`: revoke the supplied FOMO session.
- `GET /auth/me`: current account.

Protected endpoints use `Authorization: Bearer <FOMO session token>`. Supabase tokens are accepted only by the exchange endpoint. This keeps FOMO sessions compatible across blue and green releases. Supabase refresh tokens remain managed by the Flutter SDK; Google client secrets stay in Supabase provider settings.

`AUTH_MODE=password` keeps the existing API methods available and disables the new Supabase exchange. `hybrid` enables Supabase plus passwords and legacy Google clients. `google` accepts new logins only through Supabase and disables password registration/login and the legacy Google endpoint. Existing FOMO sessions remain valid until logout or reset.

## Database migration

The SQLite and Postgres user schemas already contain `google_sub` and nullable `password_hash`. No existing user fields are removed. Before enabling hybrid or google, run the additive identity-table migration once, from the backend with the same `DATABASE_URL` as the application:

```sh
python -m app.migrate_auth
```

For Supabase, use the versioned SQL in `migrations/001_supabase_auth_identities.sql`. The FOMO Supabase project already has this migration applied. The identity table has RLS enabled and no client grants. `002_restrict_backend_tables.sql` also restricts existing app tables to the trusted backend, and has been applied with user approval. Do not create browser policies for password hashes or sessions. The Python database role must have backend access (e.g. the Supabase Postgres owner); frontend public keys never provide direct app-table access.

`/health` checks the database, required migration, configured Supabase values, deployment color, and auth mode. It does not prove an end-to-end Google login has succeeded or check whether Google is enabled in Supabase. A real login is required before cutover.

## Tests

From this directory with dependencies installed:

```sh
python -m unittest discover -s tests -v
```

## Other endpoints

Events, RSVPs, friends, and follows retain their existing routes. See the API documentation at `/docs`.
