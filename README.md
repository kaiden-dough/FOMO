# FOMO

Host events, RSVP, and never miss a night out again. FOMO helps you discover events, see who's going, and keep up with friends.

**[Open the live app](https://fomo-puce.vercel.app/)**

## Features

- Discover events in a list or on a map.
- View event details, locations, and start and end times.
- Create events and manage RSVPs.
- Find and follow other users, and browse a friends feed.
- Sign up and sign in with Google through Supabase Auth.

## Tech stack

| Layer | Technology |
| --- | --- |
| Frontend | Flutter and Dart |
| API | Python, FastAPI, and Uvicorn |
| Database access | SQLAlchemy; Psycopg for PostgreSQL |
| Production database | Supabase PostgreSQL |
| Local database | SQLite by default |
| Authentication | Google OAuth through Supabase Auth, exchanged for FOMO API sessions |
| Maps | Google Maps; OpenStreetMap Nominatim for address suggestions |
| Hosting | Vercel for the web frontend; Render for the API |
| Source control | Git and GitHub |

## Architecture

The Flutter app calls the FastAPI backend for events, RSVPs, follows, and account data. The backend reads and writes the database through SQLAlchemy.

For sign-in, the app opens Google's login flow through Supabase Auth. It then sends the Supabase access token to `POST /auth/supabase`. The backend verifies the token and Google identity before issuing a FOMO session token for protected API requests.

Production app tables are restricted to backend access. The frontend uses a public Supabase publishable key; database credentials and the Google OAuth client secret stay on the server or in Supabase's provider settings.

## Repository structure

```text
FOMO/
├── README.md
└── fomo/
    ├── backend/
    │   ├── app/             # API routes, models, authentication, and configuration
    │   ├── migrations/      # Supabase schema and access restrictions
    │   ├── tests/           # Backend authentication tests
    │   ├── .env.example
    │   └── requirements.txt
    ├── frontend/
    │   ├── lib/             # Flutter screens, widgets, and API services
    │   ├── assets/          # App images and branding
    │   ├── scripts/         # Local web runner and Vercel build script
    │   ├── web/             # Web entry point
    │   └── pubspec.yaml
    └── deploy/              # Blue/green deployment configuration and guide
```

## Run locally

### Prerequisites

- Git
- Python 3.13 (the deployed API uses 3.13.5)
- Flutter with Dart compatible with `^3.11.1`
- Chrome for the web app
- A Google Maps browser API key
- A Supabase project with Google sign-in configured if testing OAuth

The commands below use PowerShell. Run each set from the repository root unless shown otherwise.

### 1. Set up the backend

```powershell
git clone https://github.com/kaiden-dough/FOMO.git
cd FOMO
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r fomo/backend/requirements.txt
Copy-Item fomo/backend/.env.example fomo/backend/.env
```

Skip the copy command if you already have a configured `.env` file. Edit `fomo/backend/.env` with your local settings. For Google-only authentication, use:

```dotenv
DATABASE_URL=sqlite:///./fomo.db
AUTH_MODE=google
DEPLOYMENT_COLOR=local
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_PUBLISHABLE_KEY
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

Initialize the authentication identity table and start the API:

```powershell
Push-Location fomo/backend
..\..\.venv\Scripts\python.exe -m app.migrate_auth
..\..\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000
```

Keep this terminal running. The SQLite path is relative to the backend's working directory, so these commands use `fomo/backend/fomo.db`. Use the same working directory for migrations and the server.

API documentation is available at [localhost:8000/docs](http://localhost:8000/docs), and the health endpoint is [localhost:8000/health](http://localhost:8000/health).

For local password-flow development without Supabase, leave `AUTH_MODE=password` and the Supabase values empty. The live web app uses Google-only authentication.

### 2. Set up Google sign-in

In your Supabase project, enable the Google provider and configure a Google Web OAuth client. Its authorized Google redirect URI must be:

```text
https://YOUR_PROJECT.supabase.co/auth/v1/callback
```

Add `http://localhost:3000/` to Supabase Auth's allowed redirect URLs. Keep the Google client secret in Supabase; do not place it in Flutter or commit it to Git.

See the [provider and deployment guide](fomo/deploy/README.md#provider-setup) for more detail.

### 3. Start the frontend

Open another terminal at the repository root:

```powershell
cd fomo/frontend
flutter pub get
.\scripts\run_web.ps1 `
  -MapsApiKey "YOUR_GOOGLE_MAPS_BROWSER_KEY" `
  -SupabaseUrl "https://YOUR_PROJECT.supabase.co" `
  -SupabasePublishableKey "YOUR_PUBLIC_PUBLISHABLE_KEY"
```

The helper starts Chrome at `http://localhost:3000` and connects to `http://localhost:8000`. Use `-BackendUrl` to select a different API. It temporarily inserts your Maps key into the web entry point and restores the file when it exits.

## Configuration

| Variable | Used by | Purpose |
| --- | --- | --- |
| `DATABASE_URL` | Backend | SQLite or PostgreSQL connection string |
| `AUTH_MODE` | Backend | `password`, `hybrid`, or `google` |
| `DEPLOYMENT_COLOR` | Backend | Release identifier returned by `/health` |
| `CORS_ORIGINS` | Backend | Comma-separated allowed frontend origins |
| `SUPABASE_URL` | Backend and frontend | Supabase project URL |
| `SUPABASE_PUBLISHABLE_KEY` | Backend and frontend | Public Supabase configuration |
| `GOOGLE_CLIENT_ID` | Backend | Legacy direct Google flow in password/hybrid mode |
| `BACKEND_URL` | Frontend build | API base URL |
| `GOOGLE_MAPS_API_KEY` | Vercel build | Browser Maps key inserted by the build script |
| `AUTH_REDIRECT_URL` | Native frontend build | OAuth deep-link callback; requires platform setup |

Frontend settings are compiled into the app. Changing Vercel environment variables requires a new build. Never use a Supabase service-role or secret key as frontend configuration.

## Checks

From the repository root, run the backend and deployment-switch tests:

```powershell
Push-Location fomo/backend
..\..\.venv\Scripts\python.exe -m unittest discover -s tests -v
Pop-Location
.\.venv\Scripts\python.exe -m unittest discover -s fomo/deploy/tests -v
```

Analyze the Flutter app:

```powershell
cd fomo/frontend
flutter analyze
```

For OAuth changes, also test an actual Google sign-in, repeat login, protected account access, and logout in the target deployment. A passing health check alone does not verify the OAuth callback.

## Deployment

- **Web app:** [fomo-puce.vercel.app](https://fomo-puce.vercel.app/)
- **Active Google-only API:** [fomo-auth-green.onrender.com](https://fomo-auth-green.onrender.com/health)
- **Retained blue API:** `https://fomo-bk8f.onrender.com`, kept with the previous frontend deployment for rollback.

Vercel uses `fomo/frontend` as its root directory, runs `scripts/vercel-build.sh`, and publishes `build/web`. Configure `BACKEND_URL`, `GOOGLE_MAPS_API_KEY`, `SUPABASE_URL`, and `SUPABASE_PUBLISHABLE_KEY` for each deployment environment.

The Render API uses `fomo/backend` as its root directory, installs `requirements.txt`, and starts Uvicorn. Blue and green share the production PostgreSQL database; switching the frontend deployment changes its API destination. The retained blue service has automatic deployments disabled.

See the [blue/green rollout and rollback guide](fomo/deploy/README.md) and [backend documentation](fomo/backend/README.md) before changing production settings or running migrations. The Docker proxy configuration is an alternative for a separate Docker host; it does not control Render traffic.

## Platform status

The web app's Google sign-in is deployed and has been tested through login and logout. Native Android/iOS Maps configuration and OAuth deep links still require platform-specific setup and verification.
