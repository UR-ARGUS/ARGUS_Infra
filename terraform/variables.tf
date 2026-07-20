# ────────────────────────────────────────────────────────────────────────────
# variables.tf
# 네트워킹/엣지 계층에서 사용하는 입력 변수 정의
# ────────────────────────────────────────────────────────────────────────────

# ── 공통 ────────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름 (리소스 이름 prefix)"
  type        = string
  default     = "argus"
}

variable "environment" {
  description = "배포 환경 (dev / staging / prod)"
  type        = string
  default     = "dev"
}

# ── VPC / Subnet ────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  # Onde(10.0.0.0/16)와 대역을 분리 — 향후 VPC Peering/Transit Gateway 연결 대비
  description = "VPC CIDR 블록 (Onde와 겹치지 않도록 10.1.0.0/16 사용)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 목록 (ALB + 프론트엔드 EC2 배치)"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR 목록 (백엔드 EC2 / docker-compose 배치)"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "availability_zones" {
  description = "가용 영역 목록 (public/private 서브넷 수와 일치해야 함)"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

# ── DNS / 인증서 ────────────────────────────────────────────────────────────

variable "domain_name" {
  description = "서비스 루트 도메인 (Route53 호스티드 존 + ACM 인증서 대상)"
  type        = string
  default     = "argus.click"
}

# ── ALB / 타겟 그룹 ─────────────────────────────────────────────────────────

variable "frontend_port" {
  description = "프론트엔드(Nginx) 리슨 포트"
  type        = number
  default     = 80
}

variable "backend_port" {
  description = "백엔드 API(docker-compose) 리슨 포트"
  type        = number
  default     = 8001
}

variable "frontend_health_check_path" {
  description = "프론트엔드 타겟 그룹 헬스체크 경로"
  type        = string
  default     = "/"
}

variable "backend_health_check_path" {
  description = "백엔드 타겟 그룹 헬스체크 경로 (백엔드 팀이 실제 헬스 엔드포인트에 맞게 조정)"
  type        = string
  default     = "/health"
}
