output "release_name" {
  description = "The name of the ArgoCD Helm release"
  value       = helm_release.argocd.name
}

output "namespace" {
  description = "The namespace where ArgoCD is deployed"
  value       = var.namespace
}

output "chart_version" {
  description = "The version of the ArgoCD Helm chart deployed"
  value       = helm_release.argocd.version
}

output "server_service_name" {
  description = "The name of the ArgoCD server service"
  value       = "${var.release_name}-server"
}

output "server_service_port" {
  description = "The port of the ArgoCD server service"
  value       = 80
}

output "admin_password_secret_name" {
  description = "The name of the Kubernetes secret containing the admin password"
  value       = var.admin_password_secret_name
}

output "values_yaml" {
  description = "The final Helm values YAML used for deployment"
  value       = local.values_yaml
  sensitive   = true
}
