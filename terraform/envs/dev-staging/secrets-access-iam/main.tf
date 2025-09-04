# ========================================
# SECRETS ACCESS IAM - DEV/STAGING ENVIRONMENT  
# Creates IAM roles and policies for AWS Secrets Manager access
# ========================================

# Data source for EKS cluster
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket  = "cloudinsight-tfstate"
    key     = "dev-staging/eks.tfstate"
    region  = var.region
    encrypt = true
  }
}

# Secrets Access IAM module
module "secrets_access_iam" {
  source = "../../../modules/secrets-access-iam"

  cluster_name = data.terraform_remote_state.eks.outputs.cluster_name
  services     = var.services

  # Create shared infra role for api-gateway, config-server, service-discovery
  create_shared_infra_role = true
  shared_infra_services    = ["api-gateway", "config-server", "service-discovery"]
  environment              = var.environment

  tags = var.tags
}
