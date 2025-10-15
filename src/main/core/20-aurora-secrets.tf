locals {
  eks_secret_default_tags = {
    EKSClusterName                     = module.eks.cluster_name
    EKSClusterNamespacesSpaceSeparated = join(" ", [var.env])
    TerraformState                     = local.terraform_state
  }
}

resource "aws_secretsmanager_secret" "signal_store_pull_user" {
  count = local.use_postgresql_user_module ? 0 : 1

  name = format("rds/%s-signal-store-%s/users/pull-signal-user", local.project, var.env)

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "signal-store-pull-signal-user"
    }
  )
}

resource "aws_secretsmanager_secret" "signal_store_push_user" {
  count = local.use_postgresql_user_module ? 0 : 1

  name = format("rds/%s-signal-store-%s/users/push-signal-user", local.project, var.env)

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "signal-store-push-signal-user"
    }
  )
}

resource "aws_secretsmanager_secret" "signal_store_persister_user" {
  count = local.use_postgresql_user_module ? 0 : 1

  name = format("rds/%s-signal-store-%s/users/signal-persister-user", local.project, var.env)

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "signal-store-signal-persister-user"
    }
  )
}

resource "aws_secretsmanager_secret" "signal_store_batch_cleanup_user" {
  count = local.use_postgresql_user_module ? 0 : 1

  name = format("rds/%s-signal-store-%s/users/batch-cleanup-user", local.project, var.env)

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "signal-store-batch-cleanup-user"
    }
  )
}

resource "aws_secretsmanager_secret" "signal_store_flyway_user" {
  count = local.use_postgresql_user_module ? 0 : 1

  name = format("rds/%s-signal-store-%s/users/flyway-user", local.project, var.env)

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "signal-store-flyway-user"
    }
  )
}

resource "aws_secretsmanager_secret" "agreement_consumer_user" {
  count = local.use_postgresql_user_module ? 0 : 1

  name = format("rds/%s-signal-store-%s/users/agreement-consumer-user", local.project, var.env)

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "signal-store-agreement-consumer-user"
    }
  )
}

resource "aws_secretsmanager_secret" "eservice_consumer_user" {
  count = local.use_postgresql_user_module ? 0 : 1

  name = format("rds/%s-signal-store-%s/users/eservice-consumer-user", local.project, var.env)

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "signal-store-eservice-consumer-user"
    }
  )
}

resource "aws_secretsmanager_secret" "purpose_consumer_user" {
  count = local.use_postgresql_user_module ? 0 : 1

  name = format("rds/%s-signal-store-%s/users/purpose-consumer-user", local.project, var.env)

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "signal-store-purpose-consumer-user"
    }
  )
}

resource "aws_secretsmanager_secret" "delegation_consumer_user" {
  count = local.use_postgresql_user_module ? 0 : 1

  name = format("rds/%s-signal-store-%s/users/delegation-consumer-user", local.project, var.env)

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "signal-store-delegation-consumer-user"
    }
  )
}

resource "aws_secretsmanager_secret" "readonly_user" {
  count = local.use_postgresql_user_module ? 0 : 1

  name = format("rds/%s-signal-store-%s/users/readonly-user", local.project, var.env)

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "signal-store-readonly-user"
    }
  )
}
