output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.identifier
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "master_username" {
  description = "Master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "secret_arn" {
  description = "ARN of the AWS Secrets Manager secret containing database credentials"
  value       = data.aws_secretsmanager_secret.user_service.arn
}

output "secrets_access_role_arn" {
  description = "ARN of the IAM role for Secrets Manager access"
  value       = aws_iam_role.secrets_access.arn
}

output "secrets_access_role_name" {
  description = "Name of the IAM role for Secrets Manager access"
  value       = aws_iam_role.secrets_access.name
}

# ConfigMap Data for Kubernetes
output "configmap_data" {
  description = "Data for Kubernetes ConfigMap (basic database connection details)"
  value = {
    # Basic database connection details
    AWS_REGION = data.aws_region.current.name
    DB_HOST    = aws_db_instance.main.endpoint
    DB_PORT    = tostring(aws_db_instance.main.port)
    DB_NAME    = aws_db_instance.main.db_name
  }
}
