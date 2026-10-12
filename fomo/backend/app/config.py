import os

from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./fomo.db")
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "")

# Blue keeps password auth; green can exercise both before Google-only cutover.
AUTH_MODE = os.getenv("AUTH_MODE", "password").strip().lower()
if AUTH_MODE not in {"password", "hybrid", "google"}:
    raise ValueError("AUTH_MODE must be password, hybrid, or google")
DEPLOYMENT_COLOR = os.getenv("DEPLOYMENT_COLOR", "local")
SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip("/")
SUPABASE_PUBLISHABLE_KEY = os.getenv("SUPABASE_PUBLISHABLE_KEY", "")

_default_cors = "http://localhost:3000,http://127.0.0.1:3000"
_raw_cors_origins = os.getenv("CORS_ORIGINS", _default_cors)
CORS_ORIGINS = [origin.strip() for origin in _raw_cors_origins.split(",") if origin.strip()]
