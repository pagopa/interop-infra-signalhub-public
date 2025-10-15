module "alb_logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-alb-logs-%s", local.project, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      id         = "Expiration"
      enabled    = true
      expiration = { days : var.env == "prod" ? 93 : 32 }
    }
  ]

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "AWS" = "arn:aws:iam::635631232127:root" # ELB account id for eu-south-1. See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
        }
        Action   = "s3:PutObject"
        Resource = "${module.alb_logs_bucket.s3_bucket_arn}/*"
      }
    ]
  })
}

module "qa_only_well_known_bucket" {
  # used only for QA
  count = local.deploy_qa_infra ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = format("%s-qa-only-well-known-%s", local.project, var.env)

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  attach_public_policy = true
  attach_policy        = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${module.qa_only_well_known_bucket[0].s3_bucket_arn}/*"
      }
    ]
  })
}

module "load_testing_reports_bucket" {
  count = var.env == "dev" ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = format("%s-load-testing-reports-%s", local.project, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "athena_query_results_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-athena-query-results-%s-es1", local.project, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      id         = "Expiration"
      enabled    = true
      expiration = { days : 31 } # delete after 31 days
    }
  ]
}

module "public_assets_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = format("%s-public-assets-%s", local.project, var.env)

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  attach_public_policy = true
  attach_policy        = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${module.public_assets_bucket.s3_bucket_arn}/*"
      }
    ]
  })

  cors_rule = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://developer.pagopa.it", "https://dev.developer.pagopa.it"]
    }
  ]

  versioning = {
    enabled = true
  }
}
