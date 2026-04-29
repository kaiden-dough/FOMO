# fomo

Host events, RSVP immediately, and never miss a night out again. Discover what's happening around you, see who's going, and get on the list before it's too late. Whether you're throwing the party or looking for one — FOMO has you covered.

## Local Dev (Web)

### Backend

From repository root:

```powershell
.\.venv313\Scripts\python.exe -m pip install -r .\fomo\backend\requirements.txt
.\.venv313\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000 --app-dir .\fomo\backend
```

### Frontend

From `fomo/frontend`:

```powershell
flutter pub get
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

### Frontend (safe key injection for web)

Use the helper script so your Maps key is injected only for the run and then removed from tracked files:

```powershell
cd .\fomo\frontend
.\scripts\run_web.ps1 -MapsApiKey "YOUR_GOOGLE_MAPS_API_KEY" -GoogleWebClientId "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"
```

## Deploy frontend (Vercel)

Deploys from the Vercel dashboard by connecting this Git repository (no GitHub Actions).

1. **New Vercel project** → Import the repo → set **Root Directory** to `fomo/frontend`.
2. **Environment variables** (Project → Settings → Environment Variables), for Production and Preview as you prefer:
   - `BACKEND_URL` — your deployed API base URL (for example `https://your-api.onrender.com`)
   - `GOOGLE_WEB_CLIENT_ID` — OAuth web client ID used by `google_sign_in` on web
   - `GOOGLE_MAPS_API_KEY` — browser Maps JavaScript API key
3. Each deploy runs `scripts/vercel-build.sh`: installs Flutter stable, injects `GOOGLE_MAPS_API_KEY` into `web/index.html`, then runs `flutter build web`. Output is `build/web` (configured in `vercel.json`).

First builds can take several minutes while Flutter is cloned and cached.

### Required setup (same as before)

- Keep `frontend/web/index.html` with `YOUR_GOOGLE_MAPS_API_KEY` placeholder; Vercel replaces it from `GOOGLE_MAPS_API_KEY` during build.
- In `frontend/android/app/src/main/AndroidManifest.xml`, replace `YOUR_GOOGLE_MAPS_API_KEY` for Android map support.
- In `backend/.env`, set `GOOGLE_CLIENT_ID` to your OAuth web client ID (recommended).