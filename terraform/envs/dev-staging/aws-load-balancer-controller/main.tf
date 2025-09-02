locals {
  base_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "aws-load-balancer-controller"
    CostCenter  = "${var.project_name}-${var.environment}"
  }, var.tags)
}

module "aws_load_balancer_controller" {
  source               = "../../../modules/aws-load-balancer-controller"
  cluster_name         = data.terraform_remote_state.eks.outputs.cluster_name
  vpc_id               = data.terraform_remote_state.networking.outputs.vpc_id
  region               = var.region
  chart_version        = var.chart_version
  service_account_name = "aws-load-balancer-controller"
  namespace            = "kube-system"
}

output "aws_lbc_role_arn" { value = module.aws_load_balancer_controller.aws_lbc_role_arn }
output "aws_lbc_service_account" { value = module.aws_load_balancer_controller.aws_lbc_service_account }
