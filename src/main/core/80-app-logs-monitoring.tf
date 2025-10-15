resource "aws_cloudwatch_metric_alarm" "signal_persister_dead_signal_errors" {
  alarm_name        = format("k8s-signal-persister-dead-signal-errors-%s", var.env)
  alarm_description = "'Dead Signal errors in signal-persister microservice"

  alarm_actions = [aws_sns_topic.platform_alarms.arn]

  metric_name = aws_cloudwatch_log_metric_filter.dead_signal.metric_transformation[0].name
  namespace   = aws_cloudwatch_log_metric_filter.dead_signal.metric_transformation[0].namespace

  dimensions = {
    PodApp       = format("%s-be-signal-persister", local.project)
    PodNamespace = var.env
  }

  comparison_operator = "GreaterThanThreshold"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  threshold           = 0
  period              = 60 # 1 minute
  evaluation_periods  = 5
  datapoints_to_alarm = 1
}
