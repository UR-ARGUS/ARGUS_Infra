#!/usr/bin/env bash
# deploy-backend.sh - inject secrets, write prod compose, ECR pull + compose up on Backend EC2
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
CD_DIR="${ROOT}/scripts/cd"

: "${BACKEND_INSTANCE_ID:?BACKEND_INSTANCE_ID is required}"
: "${ECR_REGISTRY:?ECR_REGISTRY is required}"

PROJECT_NAME="${PROJECT_NAME:-argus}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
AWS_REGION="${AWS_REGION:-ap-northeast-2}"
export AWS_REGION

BACKEND_IMAGE="${ECR_REGISTRY}/${PROJECT_NAME}-${ENVIRONMENT}-backend:${IMAGE_TAG}"

echo "==> Deploy backend"
echo "    instance=${BACKEND_INSTANCE_ID}"
echo "    image=${BACKEND_IMAGE}"

"${CD_DIR}/wait-ssm-online.sh" "${BACKEND_INSTANCE_ID}"

COMPOSE_CONTENT="$(
  sed \
    -e "s|__ECR_REGISTRY__|${ECR_REGISTRY}|g" \
    -e "s|__PROJECT_NAME__|${PROJECT_NAME}|g" \
    -e "s|__ENVIRONMENT__|${ENVIRONMENT}|g" \
    -e "s|__IMAGE_TAG__|${IMAGE_TAG}|g" \
    "${CD_DIR}/docker-compose.prod.yml.tpl"
)"

COMPOSE_B64="$(printf '%s' "$COMPOSE_CONTENT" | base64 -w 0 2>/dev/null || printf '%s' "$COMPOSE_CONTENT" | base64 | tr -d '\n')"

REMOTE="$(cat <<EOF
set -euo pipefail
export AWS_REGION=${AWS_REGION}
mkdir -p /opt/argus
bash /opt/argus/scripts/inject-secrets.sh
aws ecr get-login-password --region ${AWS_REGION} \
  | docker login --username AWS --password-stdin ${ECR_REGISTRY}
echo '${COMPOSE_B64}' | base64 -d > /opt/argus/docker-compose.prod.yml
cd /opt/argus
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d --remove-orphans
docker compose -f docker-compose.prod.yml ps
EOF
)"

"${CD_DIR}/ssm-run.sh" "${BACKEND_INSTANCE_ID}" "$REMOTE"

if [ -n "${BACKEND_TARGET_GROUP_ARN:-}" ]; then
  "${CD_DIR}/wait-target-healthy.sh" "${BACKEND_TARGET_GROUP_ARN}" "${BACKEND_INSTANCE_ID}"
fi

echo "==> Backend deploy done"
