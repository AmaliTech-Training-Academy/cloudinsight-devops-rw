output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = module.rds_iam_auth.rds_instance_id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds_iam_auth.rds_endpoint
}

output "database_name" {
  description = "Database name"
  value       = module.rds_iam_auth.database_name
}

output "secrets_access_role_arn" {
  description = "ARN of the IAM role for Secrets Manager access"
  value       = module.rds_iam_auth.secrets_access_role_arn
}

output "secret_arn" {
  description = "ARN of the AWS Secrets Manager secret containing database credentials"
  value       = module.rds_iam_auth.secret_arn
}

output "configmap_name" {
  description = "Name of the Kubernetes ConfigMap with database configuration"
  value       = kubernetes_config_map.db_config.metadata[0].name
}

output "security_group_id" {
  description = "ID of the RDS security group"
  value       = module.rds_iam_auth.security_group_id
}
