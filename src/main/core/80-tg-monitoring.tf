resource "aws_cloudwatch_metric_alarm" "pull_signal_tg_5xx" {
  alarm_name        = format("tg-pull-signal-5XX-%s", var.env)
  alarm_description = "pull-signal target group 5XX"

  metric_name = "HTTPCode_Target_5XX_Count"
  namespace   = "AWS/ApplicationELB"
  dimensions = {
    LoadBalancer = aws_lb.sh_api.arn_suffix
    TargetGroup  = aws_lb_target_group.pull_signal.arn_suffix
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.platform_alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "push_signal_tg_5xx" {
  alarm_name        = format("tg-push-signal-5XX-%s", var.env)
  alarm_description = "push-signal target group 5XX"

  metric_name = "HTTPCode_Target_5XX_Count"
  namespace   = "AWS/ApplicationELB"
  dimensions = {
    LoadBalancer = aws_lb.sh_api.arn_suffix
    TargetGroup  = aws_lb_target_group.push_signal.arn_suffix
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.platform_alarms.arn]
}
