#!/usr/bin/env bash
set -euo pipefail

FLUTTER_HOME="${FLUTTER_HOME:-$PWD/.vercel/flutter}"

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  bash scripts/vercel_install_flutter.sh
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

: "${API_BASE_URL:?Set API_BASE_URL in Vercel Project Settings > Environment Variables.}"

flutter build web --release \
  --dart-define=APP_ENV="${APP_ENV:-production}" \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=USE_MOCK_DATA="${USE_MOCK_DATA:-false}" \
  --dart-define=STORE_ID="${STORE_ID:-1}" \
  --dart-define=CUSTOMER_ID="${CUSTOMER_ID:-1}" \
  --dart-define=API_TIMEOUT_SECONDS="${API_TIMEOUT_SECONDS:-10}"
