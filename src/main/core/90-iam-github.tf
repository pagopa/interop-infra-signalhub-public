data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_monorepo_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:${var.project_monorepo_name}:*",
        "repo:pagopa/interop-signalhub-load-testing:*", # TODO: separate role
        "repo:pagopa/interop-be-signalhub-demo:*"       # TODO: separate role
      ]
    }
  }
}

resource "aws_iam_role" "github_monorepo" {
  name = format("%s-github-monorepo-%s", local.project, var.env)

  assume_role_policy = data.aws_iam_policy_document.github_monorepo_assume.json

  inline_policy {
    name = "GithubEcrPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "ecr:GetAuthorizationToken"
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:CompleteLayerUpload",
            "ecr:GetDownloadUrlForLayer",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:UploadLayerPart"
          ]
          Resource = "*"
        }
      ]
    })
  }

  # inline_policy {
  #   name = "KubeConfigPolicy"
  #
  #   policy = jsonencode({
  #     Version = "2012-10-17"
  #     Statement = [
  #       {
  #         Effect   = "Allow"
  #         Action   = "eks:DescribeCluster"
  #         Resource = module.eks.cluster_arn
  #       }
  #     ]
  #   })
  # }
}

data "aws_iam_policy_document" "github_assume_ecs" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = formatlist("repo:%s:*", toset(var.github_runners_allowed_repos))
    }
  }
}

resource "aws_iam_role" "github_ecs" {
  name = format("%s-github-ecs-%s", local.project, var.env)

  assume_role_policy = data.aws_iam_policy_document.github_assume_ecs.json

  inline_policy {
    name = "GithubEcsPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = "ecs:RunTask"
          Resource = [
            aws_ecs_task_definition.github_runner.arn_without_revision,
            "${aws_ecs_task_definition.github_runner.arn_without_revision}:*"
          ]
          Condition = {
            StringEquals = {
              "ecs:cluster" = aws_ecs_cluster.github_runners.arn
            }
          }
        },
        {
          Effect   = "Allow"
          Action   = "ecs:StopTask"
          Resource = "*"
          Condition = {
            StringEquals = {
              "ecs:cluster" = aws_ecs_cluster.github_runners.arn
            }
          }
        },
        {
          Effect = "Allow"
          Action = "iam:PassRole"
          Resource = [
            aws_iam_role.github_runner_task_exec.arn,
            aws_iam_role.github_runner_task.arn
          ]
        }
      ]
    })
  }
}

data "aws_s3_bucket" "terraform_states" {
  bucket = format("terraform-backend-%s", data.aws_caller_identity.current.account_id)
}

data "aws_dynamodb_table" "terraform_lock" {
  name = "terraform-lock"
}

data "aws_iam_policy_document" "deployment_github_repo_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [format("repo:%s:*", var.deployment_repo_name)]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.github_runner_task.arn]
    }
  }
}

locals {
  deployment_github_repo_iam_role_name = format("%s-deployment-github-repo-%s", local.project, var.env)
}

resource "aws_iam_role" "deployment_github_repo" {
  name = local.deployment_github_repo_iam_role_name

  assume_role_policy  = data.aws_iam_policy_document.deployment_github_repo_assume.json
  managed_policy_arns = [aws_iam_policy.deployment_github_repo.arn]
}

resource "aws_iam_policy" "deployment_github_repo" {
  name = "DeploymentGithubRepo"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          format("%s/%s/interop-signalhub-deployment/monitoring.tfstate", data.aws_s3_bucket.terraform_states.arn, var.env),
          format("%s/%s/interop-signalhub-deployment/secrets.tfstate", data.aws_s3_bucket.terraform_states.arn, var.env)
        ]
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = [data.aws_s3_bucket.terraform_states.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = [data.aws_dynamodb_table.terraform_lock.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetResourcePolicy"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/EKSClusterName" = module.eks.cluster_name,
            "aws:ResourceTag/TerraformState" = local.terraform_state
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:ListTagsForResource"
        ]
        Resource = format("arn:aws:cloudwatch:%s:%s:alarm:*", var.aws_region, data.aws_caller_identity.current.account_id)
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricAlarm"
        ]
        Resource = format("arn:aws:cloudwatch:%s:%s:alarm:*", var.aws_region, data.aws_caller_identity.current.account_id)
        Condition = {
          StringEqualsIfExists = {
            "aws:ResourceTag/Source" = format("https://github.com/%s", var.deployment_repo_name)
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:TagResource"
        ]
        Resource = format("arn:aws:cloudwatch:%s:%s:alarm:*", var.aws_region, data.aws_caller_identity.current.account_id)
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Source" = format("https://github.com/%s", var.deployment_repo_name),
          },
          StringEqualsIfExists = {
            "aws:RequestTag/Source" = format("https://github.com/%s", var.deployment_repo_name)
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:UntagResource"
        ]
        Resource = format("arn:aws:cloudwatch:%s:%s:alarm:*", var.aws_region, data.aws_caller_identity.current.account_id)
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Source" = format("https://github.com/%s", var.deployment_repo_name),
          },
          StringNotEqualsIfExists = {
            "aws:RequestTagKeys" = ["Source"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarms"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DeleteAlarms"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Source" = format("https://github.com/%s", var.deployment_repo_name)
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetDashboard",
          "cloudwatch:PutDashboard",
          "cloudwatch:DeleteDashboards"
        ]
        Resource = format("arn:aws:cloudwatch::%s:dashboard/k8s-*", data.aws_caller_identity.current.account_id)
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeMetricFilters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:ListTopics"
        ]
        Resource = "*"
      }
    ]
  })
}
