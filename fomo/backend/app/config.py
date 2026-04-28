import os

from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./fomo.db")
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "")

_default_cors = "http://localhost:3000,http://127.0.0.1:3000"
_raw_cors_origins = os.getenv("CORS_ORIGINS", _default_cors)
CORS_ORIGINS = [origin.strip() for origin in _raw_cors_origins.split(",") if origin.strip()]
