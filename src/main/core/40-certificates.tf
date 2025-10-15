# this is only for prod since the VPN endpoint uses SSO and doesn't require certificates from private CA
resource "aws_acm_certificate" "vpn" {
  count = var.env == "prod" ? 1 : 0

  domain_name       = format("vpn.%s", aws_route53_zone.sh_base.name)
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "vpn" {
  for_each = var.env == "prod" ? {
    for dvo in aws_acm_certificate.vpn[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.sh_base.zone_id
}

resource "aws_acm_certificate_validation" "vpn_cert_validation" {
  count = var.env == "prod" ? 1 : 0

  certificate_arn         = aws_acm_certificate.vpn[0].arn
  validation_record_fqdns = [for record in aws_route53_record.vpn : record.fqdn]
}

resource "aws_acm_certificate" "sh_api" {
  domain_name       = format("api.%s", aws_route53_zone.sh_base.name)
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "sh_api_cert_record" {
  for_each = {
    for dvo in aws_acm_certificate.sh_api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
  zone_id = aws_route53_zone.sh_base.zone_id
  ttl     = 300
}

resource "aws_acm_certificate_validation" "sh_api_cert_validation" {
  certificate_arn         = aws_acm_certificate.sh_api.arn
  validation_record_fqdns = [for record in aws_route53_record.sh_api_cert_record : record.fqdn]
}
