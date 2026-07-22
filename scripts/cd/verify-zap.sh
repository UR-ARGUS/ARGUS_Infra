#!/usr/bin/env bash
# verify-zap.sh - optional ZAP health check on Backend EC2 (soft-fail unless ZAP_VERIFY_STRICT=1)
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
CD_DIR="${ROOT}/scripts/cd"

: "${BACKEND_INSTANCE_ID:?BACKEND_INSTANCE_ID is required}"
AWS_REGION="${AWS_REGION:-ap-northeast-2}"
export AWS_REGION
STRICT="${ZAP_VERIFY_STRICT:-0}"

echo "==> Verify ZAP (strict=${STRICT})"

REMOTE='set -euo pipefail
if ! docker ps --format "{{.Names}}" | grep -qx argus-zap; then
  echo "ZAP container not running"
  exit 10
fi
curl -sf "http://127.0.0.1:8090/JSON/core/view/version/" | head -c 200
echo
'

set +e
"${CD_DIR}/ssm-run.sh" "${BACKEND_INSTANCE_ID}" "$REMOTE"
rc=$?
set -e

if [ "$rc" -eq 0 ]; then
  echo "==> ZAP OK"
  exit 0
fi

echo "==> ZAP check failed (rc=${rc})" >&2
if [ "$STRICT" = "1" ]; then
  exit "$rc"
fi
echo "==> Soft-fail: continuing (set ZAP_VERIFY_STRICT=1 to fail the job)"
exit 0
