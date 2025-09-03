project_name = "cloudinsight"
environment  = "dev-staging"
region       = "eu-west-1"

# ArgoCD Configuration
namespace     = "argocd"
release_name  = "argocd"
chart_version = "8.3.3"

# Security Configuration
server_insecure = true # For TLS termination at ingress

# Custom values for additional configuration
custom_values = {
  # Add any additional custom configuration here
  # Example:
  # configs = {
  #   cm = {
  #     "application.instanceLabelKey" = "argocd.argoproj.io/instance"
  #   }
  # }
}

tags = {
  Project     = "cloudinsight"
  Environment = "dev-staging"
  ManagedBy   = "terraform"
  Owner       = "devops-team"
}
