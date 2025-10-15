#### APP ROLES ####

module "be_pull_signal_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.1"

  role_name = format("%s-pull-signal-%s", local.be_prefix, var.env)

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.env}:${local.be_prefix}-pull-signal"]
    }
  }
}

module "be_push_signal_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.1"

  role_name = format("%s-push-signal-%s", local.be_prefix, var.env)

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.env}:${local.be_prefix}-push-signal"]
    }
  }

  role_policy_arns = {
    be_push_signal = aws_iam_policy.be_push_signal.arn
  }
}

module "be_signal_persister_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.1"

  role_name = format("%s-signal-persister-%s", local.be_prefix, var.env)

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.env}:${local.be_prefix}-signal-persister"]
    }
  }

  role_policy_arns = {
    be_signal_persister = aws_iam_policy.be_signal_persister.arn
  }
}

moved {
  from = module.be_agreement_event_consumer_irsa
  to = module.be_agreement_event_consumer_irsa[0]
}

module "be_agreement_event_consumer_irsa" {
  count = local.deploy_interop_msk_integration ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.1"

  role_name = format("%s-agreement-event-consumer-%s", local.be_prefix, var.env)

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.env}:${local.be_prefix}-agreement-event-consumer"]
    }
  }

  role_policy_arns = {
    be_agreement_event_consumer = aws_iam_policy.be_agreement_event_consumer[0].arn
  }
}

moved {
  from = module.be_eservice_event_consumer_irsa
  to = module.be_eservice_event_consumer_irsa[0]
}

module "be_eservice_event_consumer_irsa" {
  count = local.deploy_interop_msk_integration ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.1"

  role_name = format("%s-eservice-event-consumer-%s", local.be_prefix, var.env)

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.env}:${local.be_prefix}-eservice-event-consumer"]
    }
  }

  role_policy_arns = {
    be_eservice_event_consumer = aws_iam_policy.be_eservice_event_consumer[0].arn
  }
}

moved {
  from = module.be_eservice_purpose_consumer_irsa
  to   = module.be_purpose_event_consumer_irsa
}

moved {
  from = module.be_purpose_event_consumer_irsa
  to = module.be_purpose_event_consumer_irsa[0]
}

module "be_purpose_event_consumer_irsa" {
  count = local.deploy_interop_msk_integration ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.1"

  role_name = format("%s-purpose-event-consumer-%s", local.be_prefix, var.env)

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.env}:${local.be_prefix}-purpose-event-consumer"]
    }
  }

  role_policy_arns = {
    be_purpose_event_consumer = aws_iam_policy.be_purpose_event_consumer[0].arn
  }
}

moved {
  from = module.be_delegation_event_consumer_irsa
  to = module.be_delegation_event_consumer_irsa[0]
}

module "be_delegation_event_consumer_irsa" {
  count = local.deploy_interop_msk_integration ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.1"

  role_name = format("%s-delegation-event-consumer-%s", local.be_prefix, var.env)

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.env}:${local.be_prefix}-delegation-event-consumer"]
    }
  }

  role_policy_arns = {
    be_delegation_event_consumer = aws_iam_policy.be_delegation_event_consumer[0].arn
  }
}

module "be_load_testing_irsa" {
  count = var.env == "dev" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.1"

  role_name = format("%s-load-testing-%s", local.be_prefix, var.env)

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${var.env}:${local.be_prefix}-load-testing"]
    }
  }

  role_policy_arns = {
    be_load_testing = aws_iam_policy.be_load_testing[0].arn
  }
}

#### SYSTEM ROLES ####

data "aws_iam_policy" "cloudwatch_agent_server" {
  name = "CloudWatchAgentServerPolicy"
}

module "aws_lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.1"

  role_name = format("aws-load-balancer-controller-%s", var.env)

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  attach_load_balancer_controller_targetgroup_binding_only_policy = true
}

module "adot_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.1"

  role_name = format("adot-collector-%s", var.env)

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["aws-observability:adot-collector"]
    }
  }

  role_policy_arns = {
    cloudwatch = data.aws_iam_policy.cloudwatch_agent_server.arn
  }
}
