# ========================================
# ARGOCD REPOSITORY SECRET - DEV/STAGING ENVIRONMENT
# Example implementation of the argocd-repo-secret module
# ========================================

# Local variables for consistent naming and tagging
locals {
  base_tags = merge({
    Project     = "cloudinsight"
    Environment = "dev-staging"
    ManagedBy   = "terraform"
    Stack       = "argocd-repo-secret"
    CostCenter  = "cloudinsight-dev-staging"
  }, var.tags)
}

# Create ArgoCD repository secret for private Git repository
module "argocd_private_repo_secret" {
  source = "../../../modules/argocd-repo-secret"

  # Cluster and AWS configuration
  cluster_name = var.cluster_name
  aws_region   = var.aws_region

  # Repository configuration
  repository_url = var.repository_url
  secret_name    = var.secret_name

  # Kubernetes configuration
  namespace              = var.namespace
  kubernetes_secret_name = var.kubernetes_secret_name

  # Additional labels for the Kubernetes secret
  secret_labels = merge({
    environment = "dev-staging"
    managed-by  = "terraform"
    purpose     = "argocd-repository-access"
  }, var.secret_labels)

  tags = local.base_tags
}