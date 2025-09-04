# ========================================
# OUTPUTS FOR SECRETS ACCESS IAM MODULE
# ========================================

# Output map of service names to their IAM role ARNs
output "service_role_arns" {
  description = "Map of service names to their IAM role ARNs for Pod Identity associations"
  value = {
    for svc_name, role in aws_iam_role.secrets_access : svc_name => role.arn
  }
}

# Output map of service names to their IAM role names
output "service_role_names" {
  description = "Map of service names to their IAM role names"
  value = {
    for svc_name, role in aws_iam_role.secrets_access : svc_name => role.name
  }
}

# Output map of service names to their policy ARNs
output "service_policy_arns" {
  description = "Map of service names to their IAM policy ARNs"
  value = {
    for svc_name, policy in aws_iam_policy.secrets_access : svc_name => policy.arn
  }
}

# Output AWS account information
output "account_info" {
  description = "AWS account and region information"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
  }
}
