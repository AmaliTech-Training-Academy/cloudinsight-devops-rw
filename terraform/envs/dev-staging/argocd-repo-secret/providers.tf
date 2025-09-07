# ========================================
# TERRAFORM PROVIDER CONFIGURATION
# ========================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "cloudinsight"
      Environment = "dev-staging"
      ManagedBy   = "terraform"
      Component   = "argocd-repo-secret"
    }
  }
}

provider "kubernetes" {
  # Configuration should be provided via environment variables or AWS profile
  # when running in EKS cluster or with proper kubectl context
}