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

output "iam_role_arn" {
  description = "ARN of the IAM role for database access"
  value       = module.rds_iam_auth.iam_role_arn
}

output "configmap_name" {
  description = "Name of the Kubernetes ConfigMap with database configuration"
  value       = kubernetes_config_map.db_config.metadata[0].name
}

output "db_user_arns" {
  description = "ARNs of the IAM database users"
  value       = module.rds_iam_auth.db_user_arns
}