#!/usr/bin/env bash
# verify-smoke.sh - HTTP smoke: GET / and GET /api/health via SERVICE_URL
set -euo pipefail

: "${SERVICE_URL:?SERVICE_URL is required (e.g. https://argus.click)}"

SERVICE_URL="${SERVICE_URL%/}"
RETRIES="${SMOKE_RETRIES:-30}"
SLEEP_SECONDS="${SMOKE_SLEEP_SECONDS:-10}"

check() {
  local path="$1"
  local url="${SERVICE_URL}${path}"
  local i code
  echo "==> Smoke ${url}"
  for i in $(seq 1 "$RETRIES"); do
    code="$(curl -sk -o /tmp/argus-smoke.body -w '%{http_code}' "$url" || echo "000")"
    echo "    try=${i} status=${code}"
    if [ "$path" = "/api/health" ]; then
      if [ "$code" = "200" ]; then
        head -c 200 /tmp/argus-smoke.body || true
        echo
        echo "==> OK ${path}"
        return 0
      fi
    else
      case "$code" in
        200|301|302) echo "==> OK ${path}"; return 0 ;;
      esac
    fi
    sleep "$SLEEP_SECONDS"
  done
  echo "==> FAIL ${path} after ${RETRIES} tries" >&2
  return 1
}

check "/"
check "/api/health"
echo "==> Smoke passed"
