output "release_name" {
  description = "The name of the ArgoCD Helm release"
  value       = helm_release.argocd.name
}

output "namespace" {
  description = "The namespace where ArgoCD is deployed"
  value       = var.namespace
}

output "server_service_name" {
  description = "The name of the ArgoCD server service"
  value       = "${var.release_name}-server"
}

output "admin_password_secret_name" {
  description = "The name of the Kubernetes secret containing the admin password"
  value       = var.admin_password_secret_name
}
