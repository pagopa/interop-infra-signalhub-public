variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to use"
}

variable "tags" {
  type = map(any)
  default = {
    CreatedBy = "Terraform"
  }
}

variable "sso_admin_role_name" {
  type        = string
  description = "Name of the existing SSO admin role"
}

variable "vpn_saml_metadata_path" {
  type        = string
  default     = null
  description = "Relative path of VPN SAML metadata file"
}

variable "signal_store_master_username" {
  description = "Signal Store DB master username "
  type        = string
}

variable "signal_store_database_name" {
  description = "Signal Store DB name "
  type        = string
}

variable "signal_store_engine_version" {
  description = "Signal Store PostgreSQL engine version"
  type        = string
}

variable "signal_store_instance_class" {
  description = "Aurora instance class for Signal Store cluster"
  type        = string
}

variable "signal_store_number_instances" {
  description = "Number of instances of the Signal Store cluster"
  type        = number

  validation {
    condition     = var.signal_store_number_instances > 0
    error_message = "The number of instances must be greater than 0"
  }
}

variable "signal_store_ca_cert_id" {
  description = "Certificate Authority ID for Signal Store cluster"
  type        = string
}

variable "signal_store_param_group_family" {
  description = "Signal Store cluster parameter group family"
  type        = string
}

variable "interop_msk_cluster_arn" {
  description = "ARN of the Interop MSK cluster"
  type        = string
  default     = null
}

variable "eks_k8s_version" {
  type        = string
  description = "K8s version used in the EKS cluster"
}

variable "eks_vpc_cni_version" {
  type        = string
  description = "EKS vpc-cni addon version"
  default     = null
}

variable "eks_coredns_version" {
  type        = string
  description = "EKS coredns addon version"
  default     = null
}

variable "eks_kube_proxy_version" {
  type        = string
  description = "EKS kube-proxy addon version"
  default     = null
}

variable "dns_sh_base_domain" {
  description = "Base DNS domain for the SignalHub product"
  type        = string
}

variable "dns_sh_dev_ns_records" {
  description = "NS records for SignalHub 'dev' hosted zone. Used to grant DNS delegation for the subdomain"
  type        = list(string)
  default     = []
}

variable "dns_sh_vapt_ns_records" {
  description = "NS records for SignalHub 'vapt' hosted zone. Used to grant DNS delegation for the subdomain"
  type        = list(string)
  default     = []
}

variable "dns_sh_uat_ns_records" {
  description = "NS records for SignalHub 'uat' hosted zone. Used to grant DNS delegation for the subdomain"
  type        = list(string)
  default     = []
}

variable "dns_sh_att_ns_records" {
  description = "NS records for SignalHub 'att' hosted zone. Used to grant DNS delegation for the subdomain"
  type        = list(string)
  default     = []
}

variable "eks_application_log_group_name" {
  description = "Name of the application log group created by FluentBit"
  type        = string
  default     = null
}

variable "sh_api_maintenance_mode" {
  description = "Maintenance mode (503 response) for SH APIs Load Balancer"
  type        = bool
}

variable "project_monorepo_name" {
  description = "Project monorepo name (format: organization/repo-name)."
  type        = string
}

variable "github_runners_allowed_repos" {
  description = "Github repositories names (format: organization/repo-name) allowed to assume the ECS role to start/stop self-hosted runners"
  type        = list(string)
}

variable "github_runners_cpu" {
  description = "vCPU to allocate for each GH runner execution (e.g. 1024)"
  type        = number
}

variable "github_runners_memory" {
  description = "RAM to allocate for each GH runner execution (e.g. 2048)"
  type        = number
}

variable "github_runners_image_uri" {
  description = "URI of the runner image"
  type        = string
}

variable "deployment_repo_name" {
  description = "Github repository name containing deployment automation"
  type        = string
}
