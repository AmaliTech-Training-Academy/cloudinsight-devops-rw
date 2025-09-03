output "argocd_release_name" {
  description = "The name of the ArgoCD Helm release"
  value       = module.argocd.release_name
}

output "argocd_namespace" {
  description = "The namespace where ArgoCD is deployed"
  value       = module.argocd.namespace
}

output "argocd_chart_version" {
  description = "The version of the ArgoCD Helm chart deployed"
  value       = module.argocd.chart_version
}

output "argocd_server_service_name" {
  description = "The name of the ArgoCD server service"
  value       = module.argocd.server_service_name
}

output "argocd_server_service_port" {
  description = "The port of the ArgoCD server service"
  value       = module.argocd.server_service_port
}

output "argocd_admin_password_secret_name" {
  description = "The name of the Kubernetes secret containing the admin password"
  value       = module.argocd.admin_password_secret_name
}

# Convenient access information
output "argocd_access_info" {
  description = "Information for accessing ArgoCD"
  value = {
    namespace            = module.argocd.namespace
    service_name         = module.argocd.server_service_name
    service_port         = module.argocd.server_service_port
    admin_secret         = module.argocd.admin_password_secret_name
    port_forward_command = "kubectl port-forward svc/${module.argocd.server_service_name} -n ${module.argocd.namespace} 8080:${module.argocd.server_service_port}"
    get_password_command = "kubectl -n ${module.argocd.namespace} get secret ${module.argocd.admin_password_secret_name} -o jsonpath='{.data.password}' | base64 -d"
  }
}
