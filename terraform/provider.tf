# ────────────────────────────────────────────────────────────────────────────
# provider.tf
# Terraform / AWS Provider 설정
# ────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ── 원격 상태 저장소 ─────────────────────────────────
  # backend "s3" {
  #   bucket         = "argus-tfstate-bucket-<AWS_ACCOUNT_ID>"
  #   key            = "terraform/state.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "argus-tfstate-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  # Terraform으로 생성하는 모든 리소스에 공통 태그 자동 부착
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "networking-edge"
    }
  }
}
