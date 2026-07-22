#!/usr/bin/env bash
# ssm-run.sh - AWS SSM Run Command helper (send + poll until Success)
# Usage: ./ssm-run.sh <instance-id> <shell-command>
set -euo pipefail

INSTANCE_ID="${1:?usage: ssm-run.sh <instance-id> <command>}"
shift
if [ "$#" -lt 1 ]; then
  echo "usage: ssm-run.sh <instance-id> <command>" >&2
  exit 2
fi
REMOTE_CMD="$*"

REGION="${AWS_REGION:-ap-northeast-2}"
TIMEOUT_SECONDS="${SSM_TIMEOUT_SECONDS:-900}"
POLL_SECONDS="${SSM_POLL_SECONDS:-5}"

echo "==> SSM SendCommand instance=${INSTANCE_ID} region=${REGION}"
PARAMS="$(python3 -c 'import json,sys; print(json.dumps({"commands":[sys.argv[1]]}))' "$REMOTE_CMD")"
COMMAND_ID="$(
  aws ssm send-command \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --comment "argus-cd" \
    --parameters "$PARAMS" \
    --query "Command.CommandId" \
    --output text
)"
echo "    command_id=${COMMAND_ID}"

deadline=$((SECONDS + TIMEOUT_SECONDS))
while true; do
  status="$(
    aws ssm get-command-invocation \
      --region "$REGION" \
      --command-id "$COMMAND_ID" \
      --instance-id "$INSTANCE_ID" \
      --query "Status" \
      --output text 2>/dev/null || echo "Pending"
  )"
  case "$status" in
    Success)
      echo "==> SSM Success"
      aws ssm get-command-invocation \
        --region "$REGION" \
        --command-id "$COMMAND_ID" \
        --instance-id "$INSTANCE_ID" \
        --query "{Status:Status,Stdout:StandardOutputContent,Stderr:StandardErrorContent}" \
        --output json
      exit 0
      ;;
    Cancelled|TimedOut|Failed|Cancelling)
      echo "==> SSM ${status}" >&2
      aws ssm get-command-invocation \
        --region "$REGION" \
        --command-id "$COMMAND_ID" \
        --instance-id "$INSTANCE_ID" \
        --output json >&2 || true
      exit 1
      ;;
    *)
      if [ "$SECONDS" -ge "$deadline" ]; then
        echo "==> SSM timed out after ${TIMEOUT_SECONDS}s (last=${status})" >&2
        exit 1
      fi
      sleep "$POLL_SECONDS"
      ;;
  esac
done
