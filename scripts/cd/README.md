# CD scripts (SSM deploy + HTTP verify)

CloudWatch / Synthetics **미사용**. `terraform apply`는 이 레포 CD 워크플로에서 실행하지 않습니다 (통합 담당).

## Prerequisites

1. Infra apply 완료 (EC2, ALB, ECR, OIDC, Secrets, inject-secrets 배치)
2. CI가 ECR에 `argus-<env>-frontend` / `argus-<env>-backend` 이미지를 push
3. GitHub repo **Secret** / **Variables** 설정 (아래)

### Secret

| Name | Source |
|------|--------|
| `AWS_GITHUB_ACTIONS_ROLE_ARN` | terraform output `github_actions_role_arn` |

### Variables

| Name | Required | Example / source |
|------|----------|------------------|
| `FRONTEND_INSTANCE_ID` | yes | output `frontend_instance_id` |
| `BACKEND_INSTANCE_ID` | yes | output `backend_instance_id` |
| `ECR_REGISTRY` | yes | `123456789012.dkr.ecr.ap-northeast-2.amazonaws.com` |
| `SERVICE_URL` | yes | output `service_url` (`https://argus.click`) |
| `ENVIRONMENT` | no (default `dev`) | matches terraform `var.environment` |
| `FRONTEND_TARGET_GROUP_ARN` | no | output `frontend_target_group_arn` (TG healthy wait) |
| `BACKEND_TARGET_GROUP_ARN` | no | output `backend_target_group_arn` |

Image refs used by deploy scripts:

```text
${ECR_REGISTRY}/${PROJECT_NAME}-${ENVIRONMENT}-frontend:${IMAGE_TAG}
${ECR_REGISTRY}/${PROJECT_NAME}-${ENVIRONMENT}-backend:${IMAGE_TAG}
```

(`PROJECT_NAME` defaults to `argus`.)

## Workflow

Actions → **Deploy** → Run workflow (`workflow_dispatch`).

- `image_tag`: ECR tag (default `latest`)
- `run_zap`: backend ZAP container health (optional)
- `zap_strict`: fail job if ZAP check fails

Flow: OIDC → deploy backend → deploy frontend → smoke (`/` + `/api/health`) → optional ZAP.

## Local script usage (from repo root, with AWS creds)

```bash
export AWS_REGION=ap-northeast-2
export FRONTEND_INSTANCE_ID=i-...
export BACKEND_INSTANCE_ID=i-...
export ECR_REGISTRY=....dkr.ecr.ap-northeast-2.amazonaws.com
export SERVICE_URL=https://argus.click
export IMAGE_TAG=latest
export ENVIRONMENT=dev

chmod +x scripts/cd/*.sh
./scripts/cd/deploy-backend.sh
./scripts/cd/deploy-frontend.sh
./scripts/cd/verify-smoke.sh
# optional:
./scripts/cd/verify-zap.sh
```

## Files

| File | Role |
|------|------|
| `ssm-run.sh` | SSM SendCommand + poll |
| `wait-ssm-online.sh` | Wait until SSM PingStatus=Online |
| `wait-target-healthy.sh` | Wait until ALB TG target is healthy |
| `docker-compose.prod.yml.tpl` | Backend EC2 prod compose (ECR + zap; no worker/selenium yet) |
| `deploy-backend.sh` | inject-secrets → compose pull/up |
| `deploy-frontend.sh` | docker pull/run FE on :80 |
| `verify-smoke.sh` | HTTPS smoke via `SERVICE_URL` |
| `verify-zap.sh` | Optional ZAP API health on backend host |

## Notes

- Backend user_data already installs `inject-secrets.sh` at `/opt/argus/scripts/inject-secrets.sh`.
- OIDC CD IAM extras (`DescribeInstanceInformation`, `DescribeInstances`, `DescribeTargetHealth`) are in `terraform/github_oidc.tf` — **apply is owned by the integration lead**.
- worker/selenium are omitted until ARGUS_Merge compose supports them.
