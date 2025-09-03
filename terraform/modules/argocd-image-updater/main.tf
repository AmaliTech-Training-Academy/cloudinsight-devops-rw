locals {
  # Default ArgoCD Image Updater values configuration
  default_values = {
    # Service Account configuration
    serviceAccount = {
      name = var.service_account_name
    }

    # Image updater configuration
    image = {
      repository = var.image_repository
    }

    # Resources configuration
    resources = {
      limits = {
        cpu    = var.cpu_limit
        memory = var.memory_limit
      }
      requests = {
        cpu    = var.cpu_request
        memory = var.memory_request
      }
    }

    # Auth scripts configuration
    authScripts = {
      enabled = var.auth_scripts_enabled
      scripts = var.auth_scripts
    }

    # Registry configuration
    config = {
      registries = var.registries
    }

    # Log level and other settings
    logLevel = var.log_level

    # Metrics configuration
    metrics = {
      enabled = var.metrics_enabled
      port    = var.metrics_port
    }
  }

  # Merge custom values with defaults
  merged_values = merge(local.default_values, var.custom_values)

  # Convert to YAML for Helm
  values_yaml = yamlencode(local.merged_values)
}

# Deploy ArgoCD Image Updater using Helm
resource "helm_release" "argocd_image_updater" {
  name             = var.release_name
  repository       = var.repository
  chart            = "argocd-image-updater"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  values = [local.values_yaml]

  # Wait for deployment to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = var.timeout
}
