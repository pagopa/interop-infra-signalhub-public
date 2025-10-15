resource "aws_wafv2_web_acl" "sh_api" {
  name  = format("%s-api-%s", local.project, var.env)
  scope = "REGIONAL"

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "SignalHub-API-WebACL"
    sampled_requests_enabled   = false
  }

  default_action {
    allow {}
  }

  rule {
    name     = "Default"
    priority = 0

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SignalHub-API-Default"
      sampled_requests_enabled   = false
    }

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "NoUserAgent_HEADER"
          action_to_use {
            count {}
          }
        }
      }
    }
  }
}

resource "aws_wafv2_web_acl_association" "sh_api" {
  web_acl_arn  = aws_wafv2_web_acl.sh_api.arn
  resource_arn = aws_lb.sh_api.arn
}

resource "aws_cloudwatch_log_group" "waf_sh_api" {
  name = format("aws-waf-logs-signalhub-api-%s", var.env)

  retention_in_days = var.env == "prod" ? 90 : 30
  skip_destroy      = true
}

resource "aws_wafv2_web_acl_logging_configuration" "sh_api" {
  resource_arn            = aws_wafv2_web_acl.sh_api.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_sh_api.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}
