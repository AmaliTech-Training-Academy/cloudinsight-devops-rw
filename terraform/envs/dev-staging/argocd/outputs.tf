# Essential ArgoCD outputs
output "argocd_namespace" {
  description = "The namespace where ArgoCD is deployed"
  value       = module.argocd.namespace
}

output "argocd_server_service_name" {
  description = "The name of the ArgoCD server service"
  value       = module.argocd.server_service_name
}

# Access information
output "argocd_access_info" {
  description = "Information for accessing ArgoCD"
  value = {
    namespace            = module.argocd.namespace
    service_name         = module.argocd.server_service_name
    admin_secret         = module.argocd.admin_password_secret_name
    port_forward_command = "kubectl port-forward svc/${module.argocd.server_service_name} -n ${module.argocd.namespace} 8080:80"
    get_password_command = "kubectl -n ${module.argocd.namespace} get secret ${module.argocd.admin_password_secret_name} -o jsonpath='{.data.password}' | base64 -d"
  }
}
