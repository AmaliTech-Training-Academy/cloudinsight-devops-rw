# ========================================
# OUTPUTS FOR SECRETS ACCESS IAM MODULE
# ========================================

output "role_arn" {
  description = "ARN of the IAM role for secrets access"
  value       = aws_iam_role.secrets_access.arn
}

output "role_name" {
  description = "Name of the IAM role for secrets access"
  value       = aws_iam_role.secrets_access.name
}

output "policy_arn" {
  description = "ARN of the IAM policy for secrets access"
  value       = aws_iam_policy.secrets_access.arn
}

output "policy_name" {
  description = "Name of the IAM policy for secrets access"
  value       = aws_iam_policy.secrets_access.name
}

output "allowed_secrets" {
  description = "Secret patterns this role can access"
  value       = var.allowed_secret_patterns
}

output "account_info" {
  description = "AWS account and region information"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
  }
}
