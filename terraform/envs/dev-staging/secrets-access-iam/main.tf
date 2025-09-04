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
  tags         = var.tags
}
