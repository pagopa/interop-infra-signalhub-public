data "aws_subnets" "aurora_signal_store" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = toset(local.aurora_cidrs)
  }
}

resource "aws_kms_key" "signal_store" {
  description              = format("rds/%s-signal-store-%s", local.project, var.env)
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

module "signal_store" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.3.1"

  name = format("%s-signal-store-%s", local.project, var.env)

  deletion_protection        = true
  apply_immediately          = var.env != "prod"
  auto_minor_version_upgrade = false

  database_name                        = var.signal_store_database_name
  master_username                      = var.signal_store_master_username
  manage_master_user_password          = true
  manage_master_user_password_rotation = false


  engine             = "aurora-postgresql"
  engine_version     = var.signal_store_engine_version
  instance_class     = var.signal_store_instance_class
  ca_cert_identifier = var.signal_store_ca_cert_id

  instances_use_identifier_prefix = false
  instances = { for i in range(var.signal_store_number_instances) :
    "instance-${i + 1}" => {
      identifier        = "signal-store-${i + 1}"
      availability_zone = element(module.vpc.azs, i)
    }
  }

  create_db_cluster_parameter_group          = true
  db_cluster_parameter_group_use_name_prefix = false
  db_cluster_parameter_group_name            = format("%s-signal-store-%s", local.project, var.env)
  db_cluster_parameter_group_family          = var.signal_store_param_group_family

  db_cluster_parameter_group_parameters = [
    {
      name  = "rds.force_ssl"
      value = 1
    }
  ]

  vpc_id             = module.vpc.vpc_id
  subnets            = data.aws_subnets.aurora_signal_store.ids
  availability_zones = module.vpc.azs

  create_db_subnet_group = true
  db_subnet_group_name   = format("%s-signal-store-%s", local.project, var.env)

  create_security_group          = true
  security_group_use_name_prefix = false
  security_group_name            = format("rds/%s-signal-store-%s", local.project, var.env)

  security_group_rules = {
    from_eks_cluster = {
      type                     = "ingress"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.eks.cluster_primary_security_group_id
      description              = "From EKS cluster"
    }

    from_vpn_clients = {
      type                     = "ingress"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.vpn_clients.id
      description              = "From VPN clients"
    }
  }

  storage_encrypted       = true
  kms_key_id              = aws_kms_key.signal_store.arn
  backup_retention_period = var.env == "prod" ? 35 : 7
  skip_final_snapshot     = false

  create_cloudwatch_log_group            = true
  enabled_cloudwatch_logs_exports        = ["postgresql"]
  cloudwatch_log_group_retention_in_days = var.env == "prod" ? 180 : 30

  create_monitoring_role                = true
  iam_role_name                         = format("%s-signal-store-enhanced-monitoring-%s", local.project, var.env)
  performance_insights_enabled          = true
  performance_insights_retention_period = var.env == "prod" ? 372 : 7
  monitoring_interval                   = 60
  performance_insights_kms_key_id       = aws_kms_key.signal_store.arn
}

# Workaround
resource "null_resource" "disable_secret_rotation" {
  triggers = {
    secret_arn = module.signal_store.cluster_master_user_secret[0].secret_arn
  }

  provisioner "local-exec" {
    on_failure = fail
    command    = "aws secretsmanager cancel-rotate-secret --secret-id ${module.signal_store.cluster_master_user_secret[0].secret_arn}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "signal_store_gh_runners" {
  count = local.deploy_qa_infra ? 1 : 0

  security_group_id = module.signal_store.security_group_id

  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.github_runners.id
  description                  = "From GH runners"
}
