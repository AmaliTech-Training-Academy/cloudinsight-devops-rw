# ========================================
# OUTPUTS FOR ARGOCD REPOSITORY SECRET MODULE
# ========================================

output "secret_name" {
  description = "Name of the created Kubernetes secret"
  value       = kubernetes_secret.argocd_repo_secret.metadata[0].name
}

output "secret_namespace" {
  description = "Namespace of the created secret"
  value       = kubernetes_secret.argocd_repo_secret.metadata[0].namespace
}

output "secret_uid" {
  description = "UID of the created secret"
  value       = kubernetes_secret.argocd_repo_secret.metadata[0].uid
}

output "repository_url" {
  description = "Git repository URL configured in the secret"
  value       = var.repository_url
}

output "aws_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret"
  value       = data.aws_secretsmanager_secret.argocd_private_key.arn
  sensitive   = true
}