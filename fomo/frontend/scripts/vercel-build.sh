#!/usr/bin/env bash
# Vercel runs this on Linux. Installs Flutter (stable) then builds web.
set -euo pipefail

if [[ -z "${BACKEND_URL:-}" || -z "${GOOGLE_WEB_CLIENT_ID:-}" ]]; then
  echo "Missing env vars: set BACKEND_URL and GOOGLE_WEB_CLIENT_ID in Vercel → Project → Settings → Environment Variables (Production + Preview as needed)."
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
flutter pub get
flutter build web --release \
  --dart-define=BACKEND_URL="${BACKEND_URL}" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="${GOOGLE_WEB_CLIENT_ID}"
