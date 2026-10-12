# Blue/green rollout for Supabase Google sign-in

This repository contains a Python/FastAPI API and Flutter frontend. Supabase hosts the database and Auth; the connected FOMO project currently has no Edge Functions. The Python API still requires its own host. This Docker setup supports two API releases on one Docker host with one shared Supabase Postgres database. It has not been started or exposed in production.

## Current hosting: Render + Vercel

The live blue API is **https://fomo-bk8f.onrender.com**. Its health check returned 200 and its routes still expose the original password/direct-Google flow. The new Supabase exchange is not live there.

The separate candidate API is provisioned at **https://fomo-auth-green.onrender.com** (Render service `srv-db6k773rjlhs73f5matg`, free plan, manual deployments, `/health` check). It uses the same Supabase Postgres database as blue and currently runs `AUTH_MODE=hybrid`. `render-green.yaml` records the equivalent infrastructure settings. The additive database and restriction migrations have already been applied to FOMO's Supabase project.

Create a Vercel preview from the feature branch with `BACKEND_URL` set to green's actual assigned Render URL, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, and the existing `GOOGLE_MAPS_API_KEY`. Allow its exact frontend URL in CORS and Supabase redirect settings. Keep the existing production frontend and blue API serving users while testing actual Google signup, repeat login, cancellation, logout, and protected actions on this preview.

Once these tests pass, set **only green** to `AUTH_MODE=google` and redeploy green; test the preview again. Configure the production environment with green's `BACKEND_URL` and the public Supabase settings, then create a staged production deployment without assigning the production domains. Test that final build before promotion: promoting a preview can rebuild with production settings, so preview verification alone is insufficient. Promote the tested production candidate to switch the frontend and API destination together. Ensure the production frontend callback URL is also allowed in Supabase. Roll back by restoring the previous Vercel production deployment, which still points at `https://fomo-bk8f.onrender.com`; keep blue and the shared database intact. Do not rebuild the old production frontend with green's URL if it is your rollback artifact.

This approach switches browser traffic using Vercel deployment promotion. It does not repoint the `fomo-bk8f.onrender.com` hostname, switch native app builds, or retire clients already using blue. Keep legacy endpoints until those clients migrate. Render's native health-gated redeploys keep the current service instance serving traffic while a new one becomes ready (except services with a persistent disk); they complement this two-service rollout. See [Render deploys](https://render.com/docs/deploys) and [Blueprint reference](https://render.com/docs/blueprint-spec).

The Docker proxy instructions below are an **alternative for a separate Docker host**. Do not run `switch.py` to switch Render services; it only controls the provided local Docker proxy.

## Provider setup

The existing backend environment already has a Google web client ID. Reuse its Google Cloud OAuth client if you can access the client secret, or create a new Web application client.

1. In Google Cloud's Auth Platform, configure the consent screen and test users if the app is in testing. Use only the `openid`, email, and profile scopes.
2. Add `https://getnexkcsoihpkrdcqli.supabase.co/auth/v1/callback` to the OAuth client's authorized redirect URIs.
3. In [FOMO's Supabase provider settings](https://supabase.com/dashboard/project/getnexkcsoihpkrdcqli/auth/providers), enable Google and enter the client ID and secret. Keep the secret in Supabase, never in Flutter or Git.
4. In Supabase Auth URL configuration, set the production site URL and add the exact preview URL and `http://localhost:3000/` to the redirect allow list.
5. For mobile, configure platform deep links and build with `AUTH_REDIRECT_URL` matching an allowed callback. The current implementation refuses mobile Google login until that value is set; native callback setup has not been verified.

Reference: [Supabase Google sign-in guide](https://supabase.com/docs/guides/auth/social-login/auth-google).

## Database and local setup

Both colors must share the same database and `user_sessions` table. Do not give each release a different SQLite file. The Supabase migrations in `backend/migrations` were applied during this task; rerun only when deploying a different database. Production and local users were reset at the user's request, with a local SQLite backup under the repository's ignored `.local-backups/` folder.

For local development, the backend `.env` and frontend `.env.oauth.json` have the connected project's public settings. Those files are ignored. The local database remains SQLite, not the remote Postgres database. Start the API from the repository root to keep using the existing root `fomo.db`:

```powershell
.\.venv313\Scripts\python.exe -m uvicorn app.main:app --app-dir fomo/backend --port 8000
# To test the candidate locally, set $env:AUTH_MODE = "hybrid" before starting its API.
```

Run Flutter from `frontend` using the helper with Maps key and Supabase public settings, or:

```sh
flutter run -d chrome --web-hostname localhost --web-port 3000 --dart-define-from-file=.env.oauth.json
```

The direct command still requires the existing Maps-key setup for maps.

## Two API releases

On the API host, copy `config.env.example` to `.env`. Fill the shared `DATABASE_URL` from Supabase's connection settings; use `postgresql+psycopg://` and SSL. Use a backend-only database role. Fill CORS origins and public Supabase values. Keep `GREEN_AUTH_MODE=hybrid` initially.

```sh
docker compose --env-file .env build blue green
docker compose --env-file .env up -d blue
docker compose --env-file .env run --rm --no-deps green python -m app.migrate_auth
docker compose --env-file .env up -d green proxy
```

Ports are bound to loopback: public routing entry 8080, direct blue preview 8081, direct green preview 8082. Put your host's HTTPS ingress in front of these. Keep previews private. Use immutable image tags for deployed releases and retain the previous blue image. Rebuilding both tags from new source replaces the rollback artifact; do this only for the initial baseline setup.

On later releases, build/update only the inactive color, leaving the active release running. Both current release images understand the same unchanged FOMO session format. The blue baseline also retains the legacy Google endpoint for older frontend clients.

## Preview, switch, and rollback

1. Keep the existing Vercel production deployment serving traffic. Create a preview of this branch with `BACKEND_URL` pointing to the HTTPS green API preview, plus `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, and `GOOGLE_MAPS_API_KEY`. Blue and green need CORS entries for their respective frontend origins.
2. Test actual Google signup, repeat login (same FOMO user ID), logout, a protected RSVP request, cancelled login, and denied/expired provider credentials. Mocked unit tests and `/health` are insufficient to approve OAuth cutover.
3. Keep green in hybrid mode for the first API switch so the existing production frontend's password and direct Google flows keep working. Route the stable API ingress to the tested hybrid release:

```sh
python switch.py green --oauth-verified
```

4. Build the final Vercel frontend candidate with `BACKEND_URL` pointing to the stable API ingress behind HTTPS, not the direct green preview. Test this candidate using its exact allow-listed preview URL, then promote it in Vercel. Smoke-test the production Google callback as well. This repository does not automate Vercel promotion or DNS/TLS.
5. Only after the new frontend is live and Google login passes, prepare the now-inactive blue slot for Google-only mode: set `BLUE_AUTH_MODE=google`, use a new immutable `BLUE_IMAGE` tag, build/recreate **blue only**, and test its direct preview through a frontend candidate. Green continues serving hybrid traffic during this preparation. Then route to blue with `python switch.py blue --oauth-verified`. This second swap disables password registration/login and the legacy Google route with no active API container restart. Both colors use the same session table.
6. To undo Google-only mode, route back to the retained hybrid green release: `python switch.py green --oauth-verified`. To undo the full Supabase rollout, restore the prior frontend deployment and the retained baseline image in the inactive slot, verify it, then route to it. New Google accounts have no password; a baseline password-only release cannot perform a new Supabase login, though existing FOMO sessions remain valid. Do not remove the additive identity table or reset the shared database during rollback.

`switch.py` checks candidate health/color/auth mode, validates and reloads nginx, and checks the routed color; it restores the previous routing configuration if verification fails. Active routing is stored in the Docker `router-state` volume across restarts. It requires `--oauth-verified` before routing to either slot running hybrid or Google-only mode. Keep the volume on rollback; deleting it resets routing to blue.

## Current limits

Google was disabled in the connected Supabase project's provider settings when inspected. Its client secret and Render management access were unavailable, so no real OAuth login, green Render service, Docker stack, or live traffic switch was performed. Docker Desktop's engine was not running on this machine. The committed database is a local development snapshot; do not deploy it as production data.
