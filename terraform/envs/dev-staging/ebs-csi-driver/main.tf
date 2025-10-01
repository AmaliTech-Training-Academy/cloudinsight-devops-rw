locals {
  base_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "ebs-csi-driver"
    CostCenter  = "${var.project_name}-${var.environment}"
  }, var.tags)
}

module "ebs_csi_driver" {
  source                      = "../../../modules/ebs-csi-driver"
  cluster_name                = data.terraform_remote_state.eks.outputs.cluster_name
  addon_version               = var.addon_version
  namespace                   = var.namespace
  service_account_name        = var.service_account_name
  enable_encryption           = var.enable_encryption
  resolve_conflicts_on_update = var.resolve_conflicts_on_update
  resolve_conflicts_on_create = var.resolve_conflicts_on_create
  tags                        = local.base_tags
}
