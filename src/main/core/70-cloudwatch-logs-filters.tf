resource "aws_cloudwatch_log_metric_filter" "eks_app_logs_errors" {
  name           = format("eks-application-logs-errors-%s", var.env)
  pattern        = "{ $.log = \"*ERROR*\" || $.stream = \"stderr\" }"
  log_group_name = aws_cloudwatch_log_group.eks_application.name

  metric_transformation {
    name      = "ErrorCount"
    namespace = "EKSApplicationLogsFilters"
    value     = "1"

    dimensions = {
      PodApp       = "$.pod_app"
      PodNamespace = "$.pod_namespace"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "dead_signal" {
  name           = format("%s-dead-signal-filter-%s", local.project, var.env)
  pattern        = "{ $.log = \"*[DEAD_SIGNAL]*\" }"
  log_group_name = aws_cloudwatch_log_group.eks_application.name

  metric_transformation {
    name      = "DeadSignalCount"
    namespace = "EKSApplicationLogsFilters"
    value     = "1"

    dimensions = {
      PodApp       = "$.pod_app"
      PodNamespace = "$.pod_namespace"
    }
  }
}
