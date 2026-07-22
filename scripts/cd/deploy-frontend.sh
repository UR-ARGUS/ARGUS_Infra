#!/usr/bin/env bash
# deploy-frontend.sh - ECR pull + run frontend container on port 80 (Frontend EC2)
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
CD_DIR="${ROOT}/scripts/cd"

: "${FRONTEND_INSTANCE_ID:?FRONTEND_INSTANCE_ID is required}"
: "${ECR_REGISTRY:?ECR_REGISTRY is required}"

PROJECT_NAME="${PROJECT_NAME:-argus}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
AWS_REGION="${AWS_REGION:-ap-northeast-2}"
CONTAINER_NAME="${FRONTEND_CONTAINER_NAME:-argus-frontend}"
HOST_PORT="${FRONTEND_HOST_PORT:-80}"
export AWS_REGION

FRONTEND_IMAGE="${ECR_REGISTRY}/${PROJECT_NAME}-${ENVIRONMENT}-frontend:${IMAGE_TAG}"

echo "==> Deploy frontend"
echo "    instance=${FRONTEND_INSTANCE_ID}"
echo "    image=${FRONTEND_IMAGE}"

"${CD_DIR}/wait-ssm-online.sh" "${FRONTEND_INSTANCE_ID}"

REMOTE="$(cat <<EOF
set -euo pipefail
export AWS_REGION=${AWS_REGION}
aws ecr get-login-password --region ${AWS_REGION} \
  | docker login --username AWS --password-stdin ${ECR_REGISTRY}
docker pull ${FRONTEND_IMAGE}
if docker ps -a --format '{{.Names}}' | grep -qx '${CONTAINER_NAME}'; then
  docker rm -f '${CONTAINER_NAME}'
fi
docker run -d --name '${CONTAINER_NAME}' --restart unless-stopped \
  -p ${HOST_PORT}:80 \
  ${FRONTEND_IMAGE}
docker ps --filter name=${CONTAINER_NAME}
EOF
)"

"${CD_DIR}/ssm-run.sh" "${FRONTEND_INSTANCE_ID}" "$REMOTE"

if [ -n "${FRONTEND_TARGET_GROUP_ARN:-}" ]; then
  "${CD_DIR}/wait-target-healthy.sh" "${FRONTEND_TARGET_GROUP_ARN}" "${FRONTEND_INSTANCE_ID}"
fi

echo "==> Frontend deploy done"
