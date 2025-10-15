module "signal_store_flyway_pgsql_user" {
  count = local.use_postgresql_user_module ? 1 : 0

  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/postgresql-user?ref=v1.7.1"

  username = "signalhub_flyway_user"

  generated_password_length = 30
  secret_prefix             = format("rds/%s/users/", module.signal_store.cluster_id)

  secret_tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "signal-store-flyway-user"
    }
  )

  db_host = module.signal_store.cluster_endpoint
  db_port = module.signal_store.cluster_port
  db_name = var.signal_store_database_name

  db_admin_credentials_secret_arn = module.signal_store.cluster_master_user_secret[0].secret_arn

  additional_sql_statements = <<-EOT
    GRANT CREATE ON DATABASE "${var.signal_store_database_name}" TO signalhub_flyway_user
  EOT
}

locals {
  be_app_psql_usernames = local.use_postgresql_user_module ? {
    pull_signal_user = {
      sql_name        = "pull_signal_user",
      k8s_secret_name = "signal-store-pull-signal-user"
    },
    push_signal_user = {
      sql_name        = "push_signal_user",
      k8s_secret_name = "signal-store-push-signal-user"
    },
    signal_persister_user = {
      sql_name        = "signal_persister_user",
      k8s_secret_name = "signal-store-signal-persister-user"
    },
    agreement_consumer_user = {
      sql_name        = "agreement_consumer_user",
      k8s_secret_name = "signal-store-agreement-consumer-user"
    },
    eservice_consumer_user = {
      sql_name        = "eservice_consumer_user",
      k8s_secret_name = "signal-store-eservice-consumer-user"
    },
    purpose_consumer_user = {
      sql_name        = "purpose_consumer_user",
      k8s_secret_name = "signal-store-purpose-consumer-user"
    },
    delegation_consumer_user = {
      sql_name        = "delegation_consumer_user",
      k8s_secret_name = "signal-store-delegation-consumer-user"
    },
    batch_cleanup_user = {
      sql_name        = "batch_cleanup_user",
      k8s_secret_name = "signal-store-batch-cleanup-user"
    },
    readonly_user = {
      sql_name        = "readonly_user",
      k8s_secret_name = "signal-store-readonly-user"
    }
  } : {}
}

# PostgreSQL users with no initial grants. The grants will be applied by Flyway
module "signal_store_be_app_pgsql_user" {
  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/postgresql-user?ref=v1.7.1"

  for_each = local.be_app_psql_usernames

  username = each.value.sql_name

  generated_password_length = 30
  secret_prefix             = format("rds/%s/users/", module.signal_store.cluster_id)

  secret_tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = each.value.k8s_secret_name
    }
  )

  db_host = module.signal_store.cluster_endpoint
  db_port = module.signal_store.cluster_port
  db_name = var.signal_store_database_name

  db_admin_credentials_secret_arn = module.signal_store.cluster_master_user_secret[0].secret_arn
}
