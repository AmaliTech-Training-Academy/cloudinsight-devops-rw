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

output "iam_database_users" {
  description = "List of IAM database users"
  value       = var.iam_database_users
}

output "iam_role_arn" {
  description = "ARN of the IAM role for database access"
  value       = aws_iam_role.db_access.arn
}

output "iam_role_name" {
  description = "Name of the IAM role for database access"
  value       = aws_iam_role.db_access.name
}

output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

# ConfigMap Data for Kubernetes
output "configmap_data" {
  description = "Data for Kubernetes ConfigMap (non-sensitive values)"
  value = {
    DB_HOST        = aws_db_instance.main.endpoint
    DB_PORT        = tostring(aws_db_instance.main.port)
    DB_NAME        = aws_db_instance.main.db_name
    DB_USERNAME    = var.iam_database_users[0] # Primary IAM user
    USE_IAM_AUTH   = "true"
    DB_INSTANCE_ID = aws_db_instance.main.identifier
    AWS_REGION     = data.aws_region.current.name
    IAM_ROLE_ARN   = aws_iam_role.db_access.arn
  }
}

# Database User ARNs
output "db_user_arns" {
  description = "ARNs of the IAM database users"
  value = {
    for user in var.iam_database_users : user =>
    "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.main.identifier}/${user}"
  }
}