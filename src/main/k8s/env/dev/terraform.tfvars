aws_region = "eu-south-1"
env        = "dev"

tags = {
  CreatedBy   = "Terraform"
  Environment = "dev"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-infra-signalhub"
}

eks_cluster_name = "signalhub-eks-cluster-dev"

enable_fluentbit_process_logs = false
application_log_group_name    = "/aws/eks/signalhub-eks-cluster-dev/application"

aws_lb_controller_role_name     = "aws-load-balancer-controller-dev"
aws_lb_controller_chart_version = "1.8.1"
aws_lb_controller_replicas      = 2

kube_state_metrics_image_version_tag = "v2.12.0"
kube_state_metrics_cpu               = "500m"
kube_state_metrics_memory            = "512Mi"

adot_collector_role_name = "adot-collector-dev"
adot_collector_image_uri = "amazon/aws-otel-collector:v0.30.0"
adot_collector_cpu       = "2"
adot_collector_memory    = "2Gi"
