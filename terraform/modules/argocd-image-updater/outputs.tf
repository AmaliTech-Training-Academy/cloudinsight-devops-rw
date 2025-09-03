output "release_name" {
  description = "The name of the ArgoCD Image Updater Helm release"
  value       = helm_release.argocd_image_updater.name
}

output "namespace" {
  description = "The namespace where ArgoCD Image Updater is deployed"
  value       = var.namespace
}

output "chart_version" {
  description = "The version of the ArgoCD Image Updater Helm chart deployed"
  value       = helm_release.argocd_image_updater.version
}

output "service_account_name" {
  description = "The name of the service account used by ArgoCD Image Updater"
  value       = var.service_account_name
}

output "status" {
  description = "The status of the Helm release"
  value       = helm_release.argocd_image_updater.status
}

output "values" {
  description = "The values used for the Helm deployment (sensitive)"
  value       = local.merged_values
  sensitive   = true
}
