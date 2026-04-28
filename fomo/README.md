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

## Long-term Vercel deploy (recommended)

This repository includes a GitHub Actions workflow at `.github/workflows/deploy-frontend-vercel.yml` that:

- builds Flutter web on GitHub Actions
- deploys the prebuilt output to Vercel

No Flutter runtime is required in Vercel build machines.

### Required GitHub repository secrets

- `BACKEND_URL` (your deployed backend URL)
- `GOOGLE_WEB_CLIENT_ID` (OAuth web client ID)
- `VERCEL_TOKEN` (personal token from Vercel)
- `VERCEL_ORG_ID` (from Vercel project settings)
- `VERCEL_PROJECT_ID` (from Vercel project settings)

### Required setup

- In `frontend/web/index.html`, replace `YOUR_GOOGLE_MAPS_API_KEY` with your browser maps key.
- In `frontend/android/app/src/main/AndroidManifest.xml`, replace `YOUR_GOOGLE_MAPS_API_KEY` for Android map support.
- In `backend/.env`, set `GOOGLE_CLIENT_ID` to your OAuth web client ID (recommended).