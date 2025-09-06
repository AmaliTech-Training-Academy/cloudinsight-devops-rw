# Environment Configuration
aws_region   = "eu-west-1"
environment  = "dev-staging"
project_name = "cloudinsight"

# Database Configuration
database_name   = "cloudinsight_dev"
master_username = "postgres"
# master_password will be provided via TF_VAR_master_password or -var
postgres_version = "15.4"
instance_class   = "db.t3.micro"

# Storage Configuration
allocated_storage     = 20
max_allocated_storage = 50
storage_encrypted     = true

# Backup Configuration (dev-staging settings)
backup_retention_period = 3
skip_final_snapshot     = true

# Monitoring
performance_insights_enabled = false # Disabled for cost savings in dev
monitoring_interval          = 0     # Disabled for cost savings in dev

# IAM Database Users
iam_database_users = [
  "cloudinsight_user",
  "readonly_user"
]

# Kubernetes Configuration
kubernetes_namespace       = "cloudinsight-dev"
kubernetes_service_account = "cloudinsight-sa"