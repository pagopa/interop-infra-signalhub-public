terraform {
  required_version = "~> 1.8.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.88.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }

  # avoid drift between VPC module and K8s tags applied only for some specific subnets
  ignore_tags {
    keys = ["kubernetes.io/role/elb", "kubernetes.io/role/internal-elb"]
  }
}

locals {
  project                         = "signalhub"
  be_prefix                       = format("%s-be", local.project)
  deploy_qa_infra                 = var.env == "dev"
  deploy_interop_msk_integration  = var.env != "qa" && var.env != "vapt" && var.interop_msk_cluster_arn != null
  terraform_state                 = "core"
  use_postgresql_user_module      = var.env == "vapt"
  deploy_uptime_cost_optimization = var.env == "dev" || var.env == "vapt"
}

data "aws_iam_role" "sso_admin" {
  name = var.sso_admin_role_name
}

data "aws_caller_identity" "current" {}
