locals {
  base_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "ecr"
    CostCenter  = "${var.project_name}-${var.environment}"
  }, var.tags)
}

module "ecr" {
  source = "../../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment

  # Use default repositories list (all CloudInsight services)
  # repositories are defined in the module variables.tf

  # ECR Configuration
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true

  tags = local.base_tags
}
