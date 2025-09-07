# ========================================
# OUTPUTS FOR ARGOCD REPOSITORY SECRET - DEV/STAGING
# ========================================

output "secret_name" {
  description = "Name of the created Kubernetes secret"
  value       = module.argocd_private_repo_secret.secret_name
}

output "secret_namespace" {
  description = "Namespace of the created secret"
  value       = module.argocd_private_repo_secret.secret_namespace
}

output "secret_uid" {
  description = "UID of the created secret"
  value       = module.argocd_private_repo_secret.secret_uid
}

output "repository_url" {
  description = "Git repository URL configured in the secret"
  value       = module.argocd_private_repo_secret.repository_url
}

output "aws_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret"
  value       = module.argocd_private_repo_secret.aws_secret_arn
  sensitive   = true
}