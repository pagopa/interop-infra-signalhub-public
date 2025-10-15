locals {
  # TODO: temporary
  repository_names = var.env == "prod" ? [
    "signalhub-be-agreement-event-consumer",
    "signalhub-be-batch-cleanup",
    "signalhub-be-delegation-event-consumer",
    "signalhub-be-demo-producer-eservice-dd",
    "signalhub-be-eservice-event-consumer",
    "signalhub-be-load-testing",
    "signalhub-be-pull-signal",
    "signalhub-be-purpose-event-consumer",
    "signalhub-be-push-signal",
    "signalhub-be-signal-persister"
  ] : []
}

resource "aws_ecr_repository" "app" {
  for_each = toset([for repo in local.repository_names : repo if var.env == "prod"])

  image_tag_mutability = "MUTABLE" # needed to overwrite 'latest' tag
  name                 = each.value
}

resource "aws_ecr_lifecycle_policy" "delete_untagged" {
  for_each = aws_ecr_repository.app

  repository = each.value.name
  policy     = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Delete untagged images",
        "selection": {
          "tagStatus": "untagged",
          "countType": "sinceImagePushed",
          "countUnit": "days",
          "countNumber": 31
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  EOF
}

resource "aws_ecr_repository_policy" "cross_account_pull" {
  for_each = aws_ecr_repository.app

  repository = each.value.name

  policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Sid    = "DEV Image Pull",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::058264553932:root"
        },
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      },
      {
        Sid    = "VAPT Image Pull",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::329599626446:root"
        },
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      },
      {
        Sid    = "UAT Image Pull",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::654654262692:root"
        },
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      },
      {
        Sid    = "ATT Image Pull",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::861276092552:root"
        },
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  })
}
