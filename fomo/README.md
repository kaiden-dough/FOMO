# FOMO

Host events, RSVP immediately, and never miss a night out again.

FOMO uses a Flutter frontend and a Python/FastAPI backend. The live API is hosted at https://fomo-bk8f.onrender.com. Supabase supplies production Postgres and, for the new Google flow, Supabase Auth. The previous direct Google login remains available on the blue API until cutover.

See [backend setup](backend/README.md) and the [Google OAuth blue/green rollout guide](deploy/README.md) for provider setup, migrations, preview validation, switching, and rollback.

## Vercel frontend

Connect this repository in Vercel with Root Directory `fomo/frontend`. The existing `vercel.json` runs `scripts/vercel-build.sh` and publishes `build/web`.

Required build variables: `BACKEND_URL`, `GOOGLE_MAPS_API_KEY`. For Google sign-in also set `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` together. These two Supabase values are public browser configuration, not a service-role key. Set separate backend URLs for preview and production; the Render rollout switches the production frontend and its built-in backend URL together by promoting the tested Vercel deployment.

Keep the Maps placeholder in `web/index.html`; the build script injects the existing browser Maps key. Native Maps and OAuth deep links still require platform setup.

Local web helper:

```powershell
cd fomo/frontend
.\scripts\run_web.ps1 -MapsApiKey "YOUR_MAPS_KEY" -SupabaseUrl "https://PROJECT.supabase.co" -SupabasePublishableKey "YOUR_PUBLIC_KEY"
```
