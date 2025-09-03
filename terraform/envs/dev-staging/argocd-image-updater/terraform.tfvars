# Environment Configuration
region       = "eu-west-1"
project_name = "cloudinsight"
environment  = "dev-staging"

# ArgoCD Image Updater Configuration
release_name  = "argocd-image-updater"
chart_version = "0.12.3"
namespace     = "argocd"

# Resource Configuration (optimized for development)
cpu_limit      = "200m"
memory_limit   = "256Mi"
cpu_request    = "100m"
memory_request = "128Mi"

# Logging and Monitoring
log_level       = "info"
metrics_enabled = true

# Tags
tags = {
  Project     = "cloudinsight"
  Environment = "dev-staging"
  Component   = "argocd-image-updater"
  ManagedBy   = "terraform"
}
