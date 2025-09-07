# ========================================
# ARGOCD REPOSITORY SECRET MODULE
# Creates Kubernetes secrets for ArgoCD to access private Git repositories
# Retrieves SSH private keys from AWS Secrets Manager using Pod Identity
# ========================================

# Data source to retrieve current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Data source to retrieve the secret from AWS Secrets Manager
data "aws_secretsmanager_secret" "argocd_private_key" {
  name = var.secret_name
}

# Data source to get the actual secret value
data "aws_secretsmanager_secret_version" "argocd_private_key" {
  secret_id = data.aws_secretsmanager_secret.argocd_private_key.id
}

# Create Kubernetes secret for ArgoCD repository access
resource "kubernetes_secret" "argocd_repo_secret" {
  metadata {
    name      = var.kubernetes_secret_name
    namespace = var.namespace

    # Required ArgoCD annotations
    annotations = {
      "argocd.argoproj.io/secret-type" = "repository"
    }

    # Labels for the secret
    labels = merge({
      "argocd.argoproj.io/secret-type" = "repository"
      "app.kubernetes.io/name"         = "argocd"
      "app.kubernetes.io/component"    = "repository-secret"
      "app.kubernetes.io/managed-by"   = "terraform"
    }, var.secret_labels)
  }

  # Secret data in the format required by ArgoCD
  data = {
    type          = "git"
    url           = var.repository_url
    sshPrivateKey = base64encode(data.aws_secretsmanager_secret_version.argocd_private_key.secret_string)
  }

  type = "Opaque"
}