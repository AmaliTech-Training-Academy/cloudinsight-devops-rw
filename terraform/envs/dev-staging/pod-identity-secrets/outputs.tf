# ========================================
# OUTPUTS FOR POD IDENTITY SECRETS - DEV/STAGING
# ========================================

output "pod_identity_associations" {
  description = "All Pod Identity associations created"
  value       = module.pod_identity_secrets.pod_identity_associations
}

output "microservices_summary" {
  description = "Summary of all microservices configured with Pod Identity"
  value       = module.pod_identity_secrets.microservices_summary
}

output "verification_commands" {
  description = "Commands to verify Pod Identity associations"
  value       = module.pod_identity_secrets.verification_commands
}
