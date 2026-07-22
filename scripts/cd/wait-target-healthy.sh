#!/usr/bin/env bash
# wait-target-healthy.sh - poll ALB target group until instance is healthy
set -euo pipefail

TG_ARN="${1:?usage: wait-target-healthy.sh <tg-arn> <instance-id>}"
INSTANCE_ID="${2:?usage: wait-target-healthy.sh <tg-arn> <instance-id>}"
REGION="${AWS_REGION:-ap-northeast-2}"
TIMEOUT_SECONDS="${TG_HEALTH_TIMEOUT_SECONDS:-600}"
POLL_SECONDS="${SSM_POLL_SECONDS:-10}"

echo "==> Waiting for target healthy: ${INSTANCE_ID}"
deadline=$((SECONDS + TIMEOUT_SECONDS))
while true; do
  state="$(
    aws elbv2 describe-target-health \
      --region "$REGION" \
      --target-group-arn "$TG_ARN" \
      --targets "Id=${INSTANCE_ID}" \
      --query "TargetHealthDescriptions[0].TargetHealth.State" \
      --output text 2>/dev/null || echo "unknown"
  )"
  echo "    state=${state}"
  if [ "$state" = "healthy" ]; then
    echo "==> Target healthy"
    exit 0
  fi
  if [ "$SECONDS" -ge "$deadline" ]; then
    echo "==> Target not healthy after ${TIMEOUT_SECONDS}s (state=${state})" >&2
    exit 1
  fi
  sleep "$POLL_SECONDS"
done
