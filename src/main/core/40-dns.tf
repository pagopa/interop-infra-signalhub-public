locals {
  delegate_sh_dev_subdomain  = var.env == "prod" && length(toset(var.dns_sh_dev_ns_records)) > 0
  delegate_sh_vapt_subdomain = var.env == "prod" && length(toset(var.dns_sh_vapt_ns_records)) > 0
  delegate_sh_uat_subdomain  = var.env == "prod" && length(toset(var.dns_sh_uat_ns_records)) > 0
  delegate_sh_att_subdomain  = var.env == "prod" && length(toset(var.dns_sh_att_ns_records)) > 0
}

resource "aws_route53_zone" "sh_base" {
  name = var.dns_sh_base_domain
}

resource "aws_route53_record" "sh_dev_delegation" {
  count = local.delegate_sh_dev_subdomain ? 1 : 0

  zone_id = aws_route53_zone.sh_base.zone_id
  name    = format("dev.%s", var.dns_sh_base_domain)
  type    = "NS"
  records = toset(var.dns_sh_dev_ns_records)
  ttl     = "300"
}

resource "aws_route53_record" "sh_vapt_delegation" {
  count = local.delegate_sh_vapt_subdomain ? 1 : 0

  zone_id = aws_route53_zone.sh_base.zone_id
  name    = format("vapt.%s", var.dns_sh_base_domain)
  type    = "NS"
  records = toset(var.dns_sh_vapt_ns_records)
  ttl     = "300"
}

resource "aws_route53_record" "sh_uat_delegation" {
  count = local.delegate_sh_uat_subdomain ? 1 : 0

  zone_id = aws_route53_zone.sh_base.zone_id
  name    = format("uat.%s", var.dns_sh_base_domain)
  type    = "NS"
  records = toset(var.dns_sh_uat_ns_records)
  ttl     = "300"
}

resource "aws_route53_record" "sh_att_delegation" {
  count = local.delegate_sh_att_subdomain ? 1 : 0

  zone_id = aws_route53_zone.sh_base.zone_id
  name    = format("att.%s", var.dns_sh_base_domain)
  type    = "NS"
  records = toset(var.dns_sh_att_ns_records)
  ttl     = "300"
}
