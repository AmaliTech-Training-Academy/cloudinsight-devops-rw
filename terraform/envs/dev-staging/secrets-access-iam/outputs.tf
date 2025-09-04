# ========================================
# OUTPUTS FOR SECRETS ACCESS IAM - DEV/STAGING
# ========================================

# Output service role ARNs for use in Pod Identity associations
output "service_role_arns" {
  description = "Map of service names to their IAM role ARNs"
  value       = module.secrets_access_iam.service_role_arns
}

# Output service role names
output "service_role_names" {
  description = "Map of service names to their IAM role names"
  value       = module.secrets_access_iam.service_role_names
}

# Output service policy ARNs
output "service_policy_arns" {
  description = "Map of service names to their IAM policy ARNs"
  value       = module.secrets_access_iam.service_policy_arns
}

# Output account information
output "account_info" {
  description = "AWS account and region information"
  value       = module.secrets_access_iam.account_info
}
