# ========================================
# POD IDENTITY SECRETS - DEV/STAGING ENVIRONMENT  
# Creates Pod Identity associations for microservices
# Links Kubernetes ServiceAccounts to AWS IAM roles
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

# Data source for secrets-access-iam module outputs
data "terraform_remote_state" "secrets_access_iam" {
  backend = "s3"
  config = {
    bucket  = "cloudinsight-tfstate"
    key     = "dev-staging/secrets-access-iam.tfstate"
    region  = var.region
    encrypt = true
  }
}

# Pod Identity Secrets module
module "pod_identity_secrets" {
  source = "../../../modules/pod-identity-secrets"

  cluster_name = data.terraform_remote_state.eks.outputs.cluster_name

  # Microservices with their namespaces, service accounts, and IAM role ARNs
  microservices = [
    {
      name            = "frontend"
      namespace       = "frontend-dev"
      service_account = "secrets-access-sa"
      role_arn        = data.terraform_remote_state.secrets_access_iam.outputs.service_role_arns["frontend"]
    },
    # Shared infra services use the same role and namespace
    {
      name            = "shared-infra"
      namespace       = "infra-dev"
      service_account = "secrets-access-sa"
      role_arn        = data.terraform_remote_state.secrets_access_iam.outputs.shared_infra_role_arn
    },
    {
      name            = "user-service"
      namespace       = "user-service-dev"
      service_account = "secrets-access-sa"
      role_arn        = data.terraform_remote_state.secrets_access_iam.outputs.service_role_arns["user-service"]
    },
    {
      name            = "cost-service"
      namespace       = "cost-service-dev"
      service_account = "secrets-access-sa"
      role_arn        = data.terraform_remote_state.secrets_access_iam.outputs.service_role_arns["cost-service"]
    },
    {
      name            = "metric-service"
      namespace       = "metric-service-dev"
      service_account = "secrets-access-sa"
      role_arn        = data.terraform_remote_state.secrets_access_iam.outputs.service_role_arns["metric-service"]
    },
    {
      name            = "anomaly-service"
      namespace       = "anomaly-service-dev"
      service_account = "secrets-access-sa"
      role_arn        = data.terraform_remote_state.secrets_access_iam.outputs.service_role_arns["anomaly-service"]
    },
    {
      name            = "forecast-service"
      namespace       = "forecast-service-dev"
      service_account = "secrets-access-sa"
      role_arn        = data.terraform_remote_state.secrets_access_iam.outputs.service_role_arns["forecast-service"]
    },
    {
      name            = "notification-service"
      namespace       = "notification-service-dev"
      service_account = "secrets-access-sa"
      role_arn        = data.terraform_remote_state.secrets_access_iam.outputs.service_role_arns["notification-service"]
    }
  ]

  tags = var.tags
}
