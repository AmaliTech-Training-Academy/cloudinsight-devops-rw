locals {
  base_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "cluster-autoscaler"
    CostCenter  = "${var.project_name}-${var.environment}"
  }, var.tags)
}

module "cluster_autoscaler" {
  source               = "../../../modules/cluster-autoscaler"
  cluster_name         = data.terraform_remote_state.eks.outputs.cluster_name
  chart_version        = var.chart_version
  aws_region           = var.region
  service_account_name = "cluster-autoscaler"
  namespace            = "kube-system"
  repository           = "https://kubernetes.github.io/autoscaler"
}

output "cluster_autoscaler_role_arn" { value = module.cluster_autoscaler.cluster_autoscaler_role_arn }
output "cluster_autoscaler_service_account" { value = module.cluster_autoscaler.cluster_autoscaler_service_account }
