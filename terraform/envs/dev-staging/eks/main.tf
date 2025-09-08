data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket  = "cloudinsight-tfstate"
    key     = "dev-staging/networking.tfstate"
    region  = var.region
    encrypt = true
  }
}

locals {
  base_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "eks"
    CostCenter  = "${var.project_name}-${var.environment}"
  }, var.tags)
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids
}

module "eks" {
  source               = "../../../modules/eks"
  project_name         = var.project_name
  environment          = var.environment
  cluster_version      = var.cluster_version
  private_subnet_ids   = local.private_subnet_ids
  tags                 = local.base_tags
  node_group_name      = var.node_group_name
  node_instance_types  = var.node_instance_types
  node_capacity_type   = var.node_capacity_type
  node_min_size        = var.node_min_size
  node_desired_size    = var.node_desired_size
  node_max_size        = var.node_max_size
  node_max_unavailable = var.node_max_unavailable
  node_labels          = var.node_labels
}

output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_version" { value = module.eks.cluster_version }
output "cluster_arn" { value = module.eks.cluster_arn }
output "cluster_certificate_authority_data" { value = module.eks.cluster_certificate_authority_data }
output "cluster_security_group_id" { value = module.eks.cluster_security_group_id }
output "vpc_id" { value = module.eks.vpc_id }
output "node_group_name" { value = module.eks.node_group_name }
output "node_role_arn" { value = module.eks.node_role_arn }
