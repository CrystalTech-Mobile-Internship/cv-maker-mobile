#!/usr/bin/env bash
# Builds the Flutter web app on Vercel.
#
# Vercel has no Flutter preinstalled, so this script fetches the pinned
# Flutter SDK, writes `.env` from the project's Environment Variables (the
# file is not in Git) and outputs the site to build/web.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.6}"
FLUTTER_DIR="${HOME}/flutter-${FLUTTER_VERSION}"

# Flutter needs these tools to unpack the Dart SDK.
for tool in unzip xz which find tar gzip; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    packages="unzip xz which findutils tar gzip"
    dnf install -y ${packages} >/dev/null 2>&1 ||
      yum install -y ${packages} >/dev/null 2>&1 || true
    break
  fi
done

if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
  git clone --depth 1 --branch "${FLUTTER_VERSION}" \
    https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
fi
export PATH="${FLUTTER_DIR}/bin:${PATH}"
flutter config --no-analytics >/dev/null
flutter --version

# Public client settings only. Never add AI or service-role keys here:
# `.env` is shipped inside the web app.
: > .env
for name in \
  SUPABASE_ACTIVE_PROFILE SUPABASE_FAILOVER \
  SUPABASE_PRIMARY_URL SUPABASE_PRIMARY_ANON_KEY \
  SUPABASE_SECONDARY_URL SUPABASE_SECONDARY_ANON_KEY \
  SUPABASE_URL SUPABASE_ANON_KEY \
  AUTH_RECOVERY_CODE_IN_EMAIL \
  PAYMENT_BANK_ID PAYMENT_ACCOUNT_NUMBER PAYMENT_ACCOUNT_NAME; do
  if [ -n "${!name:-}" ]; then
    printf '%s=%s\n' "${name}" "${!name}" >> .env
  fi
done

if ! grep -qE '^SUPABASE_(PRIMARY_|SECONDARY_)?URL=' .env; then
  echo "Missing Supabase settings: add them in Vercel > Settings > Environment Variables." >&2
  exit 1
fi

flutter pub get
flutter build web --release --no-wasm-dry-run
