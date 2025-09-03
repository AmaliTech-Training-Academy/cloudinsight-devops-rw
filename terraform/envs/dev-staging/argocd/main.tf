locals {
  base_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "argocd"
    CostCenter  = "${var.project_name}-${var.environment}"
  }, var.tags)
}

module "argocd" {
  source = "../../../modules/argocd"

  cluster_name = data.terraform_remote_state.eks.outputs.cluster_name
  region       = var.region

  # ArgoCD Configuration
  namespace     = var.namespace
  release_name  = var.release_name
  chart_version = var.chart_version

  # Security Configuration
  server_insecure = var.server_insecure

  # Custom values for dev-staging environment
  custom_values = merge({
    # Development-specific overrides
    server = {
      replicas = 1 # Single replica for dev environment
      resources = {
        requests = {
          memory = "128Mi"
          cpu    = "50m"
        }
        limits = {
          memory = "256Mi"
          cpu    = "100m"
        }
      }
    }

    controller = {
      replicas = 1
      resources = {
        requests = {
          memory = "256Mi"
          cpu    = "100m"
        }
        limits = {
          memory = "512Mi"
          cpu    = "200m"
        }
      }
    }

    repoServer = {
      replicas = 1
      resources = {
        requests = {
          memory = "128Mi"
          cpu    = "50m"
        }
        limits = {
          memory = "256Mi"
          cpu    = "100m"
        }
      }
    }

    # Enable ApplicationSet for GitOps workflows
    applicationSet = {
      enabled  = true
      replicas = 1
    }

    # Redis configuration for dev
    redis = {
      enabled = true
      resources = {
        requests = {
          memory = "64Mi"
          cpu    = "25m"
        }
        limits = {
          memory = "128Mi"
          cpu    = "50m"
        }
      }
    }
  }, var.custom_values)

  tags = local.base_tags
}
