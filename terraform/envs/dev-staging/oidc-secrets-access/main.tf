# ========================================
# OIDC SECRETS ACCESS - DEV/STAGING ENVIRONMENT  
# Creates OIDC provider and IAM roles for secrets access using IRSA
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

locals {
  base_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "oidc-secrets-access"
    CostCenter  = "${var.project_name}-${var.environment}"
  }, var.tags)
}

# OIDC Secrets Access module
module "oidc_secrets_access" {
  source = "../../../modules/oidc-secrets-access"

  cluster_name = data.terraform_remote_state.eks.outputs.cluster_name

  # Define services that need secrets access
  services = [
    {
      name            = "frontend"
      namespace       = "frontend-dev"
      service_account = "frontend-sa"
    },
    {
      name            = "argocd-repo-server"
      namespace       = "argocd"
      service_account = "secrets-access-sa"
    },
    {
      name            = "cost-service"
      namespace       = "cost-service-dev"
      service_account = "cost-service-sa"
    },
    {
      name            = "metric-service"
      namespace       = "metric-service-dev"
      service_account = "metric-service-sa"
    },
    {
      name            = "anomaly-service"
      namespace       = "anomaly-service-dev"
      service_account = "anomaly-service-sa"
    },
    {
      name            = "forecast-service"
      namespace       = "forecast-service-dev"
      service_account = "forecast-service-sa"
    },
    {
      name            = "notification-service"
      namespace       = "notification-service-dev"
      service_account = "notification-service-sa"
    },
    {
      name            = "api-gateway"
      namespace       = "infra-dev"
      service_account = "api-gateway-sa"
    },
    {
      name            = "config-server"
      namespace       = "infra-dev"
      service_account = "config-server-sa"
    },
    {
      name            = "service-discovery"
      namespace       = "infra-dev"
      service_account = "service-discovery-sa"
    }
  ]

  # Allow access to all secrets (you can restrict this as needed)
  secrets_arns = ["*"]

  tags = local.base_tags
}
