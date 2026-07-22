#!/usr/bin/env bash
# wait-ssm-online.sh - poll until EC2 SSM agent is Online
set -euo pipefail

INSTANCE_ID="${1:?usage: wait-ssm-online.sh <instance-id>}"
REGION="${AWS_REGION:-ap-northeast-2}"
TIMEOUT_SECONDS="${SSM_ONLINE_TIMEOUT_SECONDS:-300}"
POLL_SECONDS="${SSM_POLL_SECONDS:-5}"

echo "==> Waiting for SSM Online: ${INSTANCE_ID}"
deadline=$((SECONDS + TIMEOUT_SECONDS))
while true; do
  ping_status="$(
    aws ssm describe-instance-information \
      --region "$REGION" \
      --filters "Key=InstanceIds,Values=${INSTANCE_ID}" \
      --query "InstanceInformationList[0].PingStatus" \
      --output text 2>/dev/null || echo "None"
  )"
  if [ "$ping_status" = "Online" ]; then
    echo "==> SSM Online"
    exit 0
  fi
  if [ "$SECONDS" -ge "$deadline" ]; then
    echo "==> SSM not Online after ${TIMEOUT_SECONDS}s (status=${ping_status})" >&2
    exit 1
  fi
  sleep "$POLL_SECONDS"
done
