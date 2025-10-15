locals {
  msk_iam_prefix = try(replace(split("/", var.interop_msk_cluster_arn)[0], ":cluster", ""), "")

  interop_msk_cluster_name = try(split("/", var.interop_msk_cluster_arn)[1], "")
  interop_msk_cluster_uuid = try(split("/", var.interop_msk_cluster_arn)[2], "")

  msk_topic_iam_prefix = "${local.msk_iam_prefix}:topic/${local.interop_msk_cluster_name}/${local.interop_msk_cluster_uuid}"
  msk_group_iam_prefix = "${local.msk_iam_prefix}:group/${local.interop_msk_cluster_name}/${local.interop_msk_cluster_uuid}"
}

resource "aws_iam_policy" "be_push_signal" {
  name = "SignalHubBePushSignal"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.push_signal.arn
      }
    ]
  })
}

resource "aws_iam_policy" "be_signal_persister" {
  name = "SignalHubBeSignalPersister"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage"
        ]
        Resource = aws_sqs_queue.push_signal.arn
    }]
  })
}

resource "aws_iam_policy" "be_agreement_event_consumer" {
  count = local.deploy_interop_msk_integration ? 1 : 0

  name = "SignalHubBeAgreementEventConsumer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          var.interop_msk_cluster_arn,
          "${local.msk_topic_iam_prefix}/outbound.*_agreement.events",
          "${local.msk_group_iam_prefix}/signalhub-${var.env}*-agreement-event-consumer"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_eservice_event_consumer" {
  count = local.deploy_interop_msk_integration ? 1 : 0

  name = "SignalHubBeEserviceEventConsumer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          var.interop_msk_cluster_arn,
          "${local.msk_topic_iam_prefix}/outbound.*_catalog.events",
          "${local.msk_group_iam_prefix}/signalhub-${var.env}*-eservice-event-consumer"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_purpose_event_consumer" {
  count = local.deploy_interop_msk_integration ? 1 : 0

  name = "SignalHubBePurposeEventConsumer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          var.interop_msk_cluster_arn,
          "${local.msk_topic_iam_prefix}/outbound.*_purpose.events",
          "${local.msk_group_iam_prefix}/signalhub-${var.env}*-purpose-event-consumer"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_delegation_event_consumer" {
  count = local.deploy_interop_msk_integration ? 1 : 0

  name = "SignalHubBeDelegationEventConsumer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          var.interop_msk_cluster_arn,
          "${local.msk_topic_iam_prefix}/outbound.*_delegation.events",
          "${local.msk_group_iam_prefix}/signalhub-${var.env}*-delegation-event-consumer"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_load_testing" {
  count = var.env == "dev" ? 1 : 0

  name = "SignalHubBeLoadTesting"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = format("%s/*", module.load_testing_reports_bucket[0].s3_bucket_arn)
      }
    ]
  })
}
