aws_region = "eu-south-1"
env        = "prod"
azs        = ["eu-south-1a", "eu-south-1b", "eu-south-1c"]

tags = {
  CreatedBy   = "Terraform"
  Environment = "prod"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-infra-signalhub"
}

sso_admin_role_name = ""

vpn_saml_metadata_path = ""

signal_store_master_username    = "root"
signal_store_database_name      = "signal_store"
signal_store_engine_version     = "16.1"
signal_store_instance_class     = "db.r6g.large"
signal_store_number_instances   = 3
signal_store_ca_cert_id         = "rds-ca-rsa2048-g1"
signal_store_param_group_family = "aurora-postgresql16"

interop_msk_cluster_arn = ""

eks_k8s_version        = "1.29"
eks_vpc_cni_version    = "v1.16.0-eksbuild.1"
eks_coredns_version    = "v1.11.1-eksbuild.4"
eks_kube_proxy_version = "v1.29.0-eksbuild.1"

dns_sh_base_domain = "signalhub.interop.pagopa.it"

dns_sh_dev_ns_records = [
]

dns_sh_vapt_ns_records = [
]

dns_sh_uat_ns_records = [
]

dns_sh_att_ns_records = [
]

eks_application_log_group_name = "/aws/eks/signalhub-eks-cluster-prod/application"

sh_api_maintenance_mode = false

project_monorepo_name = ""

github_runners_allowed_repos = []
github_runners_cpu           = 2048
github_runners_memory        = 4096
github_runners_image_uri     = "ghcr.io/pagopa/interop-github-runner-aws:v1.19.0"

deployment_repo_name = ""
