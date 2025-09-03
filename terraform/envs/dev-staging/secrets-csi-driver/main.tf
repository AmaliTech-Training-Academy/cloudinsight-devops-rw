locals {
  base_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "secrets-csi-driver"
    CostCenter  = "${var.project_name}-${var.environment}"
  }, var.tags)
}

module "secrets_csi_driver" {
  source = "../../../modules/secrets-csi-driver"

  # CSI Driver versions
  csi_driver_version   = var.csi_driver_version
  aws_provider_version = var.aws_provider_version

  # CSI Driver configuration
  sync_secret_enabled    = var.sync_secret_enabled
  enable_secret_rotation = var.enable_secret_rotation
  rotation_poll_interval = var.rotation_poll_interval

  tags = local.base_tags
}
