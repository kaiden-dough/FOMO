#!/usr/bin/env bash
# Vercel runs this on Linux. Installs Flutter (stable) then builds web.
set -euo pipefail

if [[ -z "${BACKEND_URL:-}" || -z "${GOOGLE_WEB_CLIENT_ID:-}" || -z "${GOOGLE_MAPS_API_KEY:-}" ]]; then
  echo "Missing env vars: set BACKEND_URL, GOOGLE_WEB_CLIENT_ID, and GOOGLE_MAPS_API_KEY in Vercel → Project → Settings → Environment Variables (Production + Preview as needed)."
  exit 1
fi

FLUTTER_ROOT="${HOME}/flutter_vercel"
if [[ ! -x "${FLUTTER_ROOT}/bin/flutter" ]]; then
  rm -rf "${FLUTTER_ROOT}"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${FLUTTER_ROOT}"
fi
export PATH="${FLUTTER_ROOT}/bin:${PATH}"

flutter config --no-analytics
flutter precache --web

# Inject browser Maps key at build time to avoid committing a key.
python3 - <<'PY'
from pathlib import Path
import os
import sys

index = Path("web/index.html")
placeholder = "YOUR_GOOGLE_MAPS_API_KEY"
key = os.environ["GOOGLE_MAPS_API_KEY"]
text = index.read_text(encoding="utf-8")
if placeholder not in text:
    print(f"Placeholder '{placeholder}' not found in {index}.")
    sys.exit(1)
index.write_text(text.replace(placeholder, key), encoding="utf-8")
PY

flutter pub get
flutter build web --release \
  --dart-define=BACKEND_URL="${BACKEND_URL}" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="${GOOGLE_WEB_CLIENT_ID}"
