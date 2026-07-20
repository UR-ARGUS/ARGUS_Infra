# ────────────────────────────────────────────────────────────────────────────
# dns.tf
# Route53 호스티드 존 + 서비스 도메인 A(Alias) 레코드
# ────────────────────────────────────────────────────────────────────────────

resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name = "${var.project_name}-zone"
  }
}

# ── 루트 도메인(argus.click) → ALB Alias ────────────────────────────────────
resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# ── www 서브도메인 → ALB Alias ──────────────────────────────────────────────
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
