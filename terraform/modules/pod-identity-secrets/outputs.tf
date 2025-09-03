# ========================================
# OUTPUTS FOR POD IDENTITY SECRETS MODULE
# ========================================

output "pod_identity_associations" {
  description = "All Pod Identity associations created"
  value = {
    for k, v in aws_eks_pod_identity_association.microservices : k => {
      association_arn = v.association_arn
      association_id  = v.association_id
      cluster_name    = v.cluster_name
      namespace       = v.namespace
      service_account = v.service_account
      role_arn        = v.role_arn
    }
  }
}

output "microservices_summary" {
  description = "Summary of all microservices configured"
  value = {
    for svc in var.microservices : svc.name => {
      namespace        = svc.namespace
      service_account  = svc.service_account
      pod_identity_key = "${svc.namespace}-${svc.service_account}"
      secrets_role_arn = var.secrets_role_arn
    }
  }
}

output "verification_commands" {
  description = "Commands to verify Pod Identity associations"
  value       = <<-EOT
    # List all Pod Identity associations for the cluster
    aws eks list-pod-identity-associations --cluster-name ${var.cluster_name}
    
    # Describe specific associations
    %{for k, v in aws_eks_pod_identity_association.microservices~}
    aws eks describe-pod-identity-association --cluster-name ${var.cluster_name} --association-id ${v.association_id}
    %{endfor~}
    
    # Check service accounts in namespaces
    %{for svc in var.microservices~}
    kubectl get serviceaccount ${svc.service_account} -n ${svc.namespace}
    %{endfor~}
    
    # Test Pod Identity injection (create a test pod)
    # The pod should have AWS credentials injected automatically
  EOT
}
