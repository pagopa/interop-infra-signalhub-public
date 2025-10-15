resource "aws_sqs_queue" "push_signal" {
  name = format("%s-push-signal-%s", local.project, var.env)

  message_retention_seconds = 1209600 # 14 days
  max_message_size          = 262144  # 256 KB
}

module "push_signal_sqs_monitoring" {
  source     = "./modules/queue-monitoring"
  depends_on = [aws_sqs_queue.push_signal]

  env        = var.env
  region     = var.aws_region
  queue_name = aws_sqs_queue.push_signal.name

  alarm_period             = 60 # 1 minute
  alarm_evaluation_periods = 5
  alarm_threshold_seconds  = "120" # 2 minutes
  alarm_sns_topic_arn      = aws_sns_topic.platform_alarms.arn
}
