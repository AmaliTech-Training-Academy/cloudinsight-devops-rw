output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = aws_iam_openid_connect_provider.eks.url
}

output "secrets_role_arn" {
  description = "ARN of the IAM role for secrets access"
  value       = aws_iam_role.oidc_secrets.arn
}

output "secrets_role_name" {
  description = "Name of the IAM role for secrets access"
  value       = aws_iam_role.oidc_secrets.name
}

output "secrets_policy_arn" {
  description = "ARN of the IAM policy for secrets access"
  value       = aws_iam_policy.oidc_secrets.arn
}
