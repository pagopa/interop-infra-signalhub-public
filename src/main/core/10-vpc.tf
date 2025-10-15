locals {
  eks_workload_cidrs      = ["10.0.0.0/21", "10.0.8.0/21", "10.0.16.0/21"]
  ext_lbs_cidrs           = ["10.0.24.0/22", "10.0.28.0/22", "10.0.32.0/22"]
  eks_control_plane_cidrs = ["10.0.36.0/24", "10.0.37.0/24", "10.0.38.0/24"]
  aurora_cidrs            = ["10.0.39.0/24", "10.0.40.0/24", "10.0.41.0/24"]
  vpce_cidrs              = ["10.0.42.0/24", "10.0.43.0/24", "10.0.44.0/24"]
  egress_cidrs            = ["10.0.45.0/24", "10.0.46.0/24", "10.0.47.0/24"]
  vpn_cidrs               = ["10.0.48.0/24", "10.0.49.0/24", "10.0.50.0/24"]
  msk_cidrs               = ["10.0.51.0/24", "10.0.52.0/24", "10.0.53.0/24"]

  eks_workload_subnets_names = [for idx, subn in local.eks_workload_cidrs :
  format("%s-eks-workload-%d-%s", local.project, idx + 1, var.env)]

  ext_lbs_subnets_names = [for idx, subn in local.ext_lbs_cidrs :
  format("%s-ext-lbs-%d-%s", local.project, idx + 1, var.env)]

  eks_control_plane_subnets_names = [for idx, subn in local.eks_control_plane_cidrs :
  format("%s-eks-cp-%d-%s", local.project, idx + 1, var.env)]

  aurora_subnets_names = [for idx, subn in local.aurora_cidrs :
  format("%s-aurora-%d-%s", local.project, idx + 1, var.env)]

  vpce_subnets_names = [for idx, subn in local.vpce_cidrs :
  format("%s-vpce-%d-%s", local.project, idx + 1, var.env)]

  egress_subnets_names = [for idx, subn in local.egress_cidrs :
  format("%s-egress-%d-%s", local.project, idx + 1, var.env)]

  vpn_subnets_names = [for idx, subn in local.vpn_cidrs :
  format("%s-vpn-%d-%s", local.project, idx + 1, var.env)]

  msk_subnets_names = [for idx, subn in local.msk_cidrs :
  format("%s-msk-%d-%s", local.project, idx + 1, var.env)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = format("%s-vpc-%s", local.project, var.env)
  cidr = "10.0.0.0/16"
  azs  = var.azs

  enable_dns_hostnames = true
  enable_dns_support   = true

  create_igw              = true
  map_public_ip_on_launch = false

  enable_nat_gateway = true
  single_nat_gateway = false
  # This will create N instances of NAT (N = #AZs) in the first N public subnets specified in 'public_subnets'
  one_nat_gateway_per_az = true

  # Order matters: the first N subnets (N = #AZs) will host a NAT instance. See 'one_nat_gateway_per_az'
  public_subnets = concat(
    local.egress_cidrs,
    local.ext_lbs_cidrs
  )
  public_subnet_names = concat(
    local.egress_subnets_names,
    local.ext_lbs_subnets_names
  )

  private_subnets = concat(
    local.eks_workload_cidrs,
  )
  private_subnet_names = concat(
    local.eks_workload_subnets_names
  )

  intra_subnets = concat(
    local.eks_control_plane_cidrs,
    local.vpce_cidrs,
    local.vpn_cidrs,
    local.msk_cidrs
  )
  intra_subnet_names = concat(
    local.eks_control_plane_subnets_names,
    local.vpce_subnets_names,
    local.vpn_subnets_names,
    local.msk_subnets_names
  )

  create_database_subnet_group       = false
  create_database_subnet_route_table = true
  create_database_nat_gateway_route  = false

  database_subnets = concat(
    local.aurora_cidrs
  )
  database_subnet_names = concat(
    local.aurora_subnets_names
  )

  enable_flow_log = false
}
