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

# Output shared infra role ARN
output "shared_infra_role_arn" {
  description = "ARN of the shared infra role for Pod Identity association"
  value       = module.secrets_access_iam.shared_infra_role_arn
}

# Output shared infra role name
output "shared_infra_role_name" {
  description = "Name of the shared infra role"
  value       = module.secrets_access_iam.shared_infra_role_name
}
