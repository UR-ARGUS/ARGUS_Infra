# ────────────────────────────────────────────────────────────────────────────
# outputs.tf
# ────────────────────────────────────────────────────────────────────────────

# ── VPC / Subnet ────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록 (ALB / 프론트엔드 EC2 배치)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "프라이빗 서브넷 ID 목록 (백엔드 EC2 배치)"
  value       = aws_subnet.private[*].id
}

# ── Security Group ──────────────────────────────────────────────────────────
output "alb_security_group_id" {
  description = "ALB 보안 그룹 ID"
  value       = aws_security_group.alb.id
}

output "frontend_security_group_id" {
  description = "프론트엔드 EC2 보안 그룹 ID (박진아 파트에서 참조)"
  value       = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  description = "백엔드 EC2 보안 그룹 ID (김어진 파트에서 참조)"
  value       = aws_security_group.backend.id
}

# ── ALB / Target Group ──────────────────────────────────────────────────────
output "alb_dns_name" {
  description = "ALB DNS 이름"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Route53 Zone ID (Alias 레코드용)"
  value       = aws_lb.main.zone_id
}

output "frontend_target_group_arn" {
  description = "프론트엔드 타겟 그룹 ARN"
  value       = aws_lb_target_group.frontend.arn
}

output "backend_target_group_arn" {
  description = "백엔드 타겟 그룹 ARN"
  value       = aws_lb_target_group.backend.arn
}

# ── DNS / ACM ───────────────────────────────────────────────────────────────
output "route53_zone_id" {
  description = "Route53 호스티드 존 ID (참조)"
  value       = data.aws_route53_zone.main.zone_id
}

output "route53_name_servers" {
  description = "호스티드 존 네임서버 (Route53 등록 도메인이라 자동 연결됨)"
  value       = data.aws_route53_zone.main.name_servers
}

output "acm_certificate_arn" {
  description = "검증 완료된 ACM 인증서 ARN"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "service_url" {
  description = "서비스 접속 URL"
  value       = "https://${var.domain_name}"
}
