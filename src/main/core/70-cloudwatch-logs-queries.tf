resource "aws_cloudwatch_log_group" "eks_application" {
  name = "/aws/eks/${module.eks.cluster_name}/application"

  retention_in_days = var.env == "prod" ? 180 : 90
}

resource "aws_cloudwatch_query_definition" "app_logs_errors" {
  name = "Application-Logs-Errors"

  log_group_names = [var.eks_application_log_group_name]

  query_string = <<-EOT
    fields @timestamp, @message
    | sort @timestamp desc
    | filter (@message like /ERROR/ or stream = "stderr")
    | filter @logStream not like /adot-collector/
    # | filter pod_app like /signalhub-be-pull-signal/
    # | filter pod_namespace = "${var.env}"
  EOT
}

resource "aws_cloudwatch_query_definition" "cid_tracker" {
  name = "CID-Tracker"

  log_group_names = [var.eks_application_log_group_name]

  query_string = <<-EOT
    fields @timestamp, @message
    | sort @timestamp asc
    | parse @message "[CID=*]" as CID
    | filter CID = ""
    | display @message
  EOT
}

resource "aws_cloudwatch_query_definition" "sh_api_waf_blocked" {
  name = "SH-API-WAF-Blocked-Requests"

  log_group_names = [aws_cloudwatch_log_group.waf_sh_api.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter action = "BLOCK"
    | sort @timestamp desc
  EOT
}
