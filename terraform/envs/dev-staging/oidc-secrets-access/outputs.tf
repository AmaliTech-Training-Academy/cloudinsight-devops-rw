output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = module.oidc_secrets_access.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = module.oidc_secrets_access.oidc_provider_url
}

output "secrets_role_arn" {
  description = "ARN of the IAM role for secrets access"
  value       = module.oidc_secrets_access.secrets_role_arn
}

output "secrets_role_name" {
  description = "Name of the IAM role for secrets access"
  value       = module.oidc_secrets_access.secrets_role_name
}

output "secrets_policy_arn" {
  description = "ARN of the IAM policy for secrets access"
  value       = module.oidc_secrets_access.secrets_policy_arn
}
