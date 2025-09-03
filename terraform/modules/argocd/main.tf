locals {
  # Default ArgoCD values configuration
  default_values = {
    configs = {
      params = {
        "server.insecure" = var.server_insecure
      }
    }

    # Server configuration
    server = {
      replicas = 1
      service = {
        type = "ClusterIP"
      }
      ingress = {
        enabled = false # We'll handle ingress separately
      }
    }

    # Repo server configuration
    repoServer = {
      replicas = 1
    }

    # Application controller configuration
    controller = {
      replicas = 1
    }

    # Redis configuration
    redis = {
      enabled = true
    }

    # Notifications controller
    notifications = {
      enabled  = true
      replicas = 1
    }

    # ApplicationSet controller
    applicationSet = {
      enabled  = true
      replicas = 1
    }
  }

  # Merge custom values with defaults
  merged_values = merge(local.default_values, var.custom_values)

  # Convert to YAML for Helm
  values_yaml = yamlencode(local.merged_values)
}

# Deploy ArgoCD using Helm
resource "helm_release" "argocd" {
  name             = var.release_name
  repository       = var.repository
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [local.values_yaml]

  # Wait for deployment to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 600
}
