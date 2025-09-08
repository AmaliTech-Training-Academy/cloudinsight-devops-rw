# Data source for existing Secrets Manager secret
data "aws_secretsmanager_secret" "user_service" {
  name = "user-service"
}

# IAM Role for Pod Identity (Secrets Manager access)
resource "aws_iam_role" "secrets_access" {
  name = "${var.cluster_name}-${var.environment}-secrets-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-${var.environment}-secrets-access-role"
  })
}

# IAM Policy for Secrets Manager access
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.cluster_name}-${var.environment}-secrets-access-policy"
  description = "Policy for accessing AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = data.aws_secretsmanager_secret.user_service.arn
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-${var.environment}-secrets-access-policy"
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.secrets_access.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# Pod Identity Association
resource "aws_eks_pod_identity_association" "secrets_access" {
  count = var.create_pod_identity_association ? 1 : 0

  cluster_name    = var.cluster_name
  namespace       = var.kubernetes_namespace
  service_account = var.kubernetes_service_account
  role_arn        = aws_iam_role.secrets_access.arn

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-${var.environment}-secrets-pod-identity"
  })
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-${var.environment}-db-subnet-group"
  })
}

# Validation for password requirements
check "password_requirements" {
  assert {
    condition     = var.master_password != null
    error_message = "master_password must be provided."
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.cluster_name}-${var.environment}-rds-"
  vpc_id      = var.vpc_id
  description = "Security group for RDS instance with IAM authentication"

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.eks_node_security_group_ids
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-${var.environment}-rds-sg"
  })
}

# RDS Instance with IAM Authentication
resource "aws_db_instance" "main" {
  identifier     = "${var.cluster_name}-${var.environment}-postgres"
  engine         = "postgres"
  engine_version = var.postgres_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  db_name  = var.database_name
  username = var.master_username

  # Use traditional password authentication
  password = var.master_password

  # Disable IAM database authentication for traditional setup
  iam_database_authentication_enabled = false

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period    = var.backup_retention_period
  backup_window              = var.backup_window
  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.cluster_name}-${var.environment}-final-snapshot"

  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval          = var.monitoring_interval
  monitoring_role_arn          = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-${var.environment}-postgres"
  })
}

# Optional: RDS Enhanced Monitoring Role
resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${var.cluster_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Data source to get current secret value
data "aws_secretsmanager_secret_version" "user_service_current" {
  secret_id = data.aws_secretsmanager_secret.user_service.id
}

# Store database configuration in AWS Secrets Manager
resource "aws_secretsmanager_secret_version" "user_service_db_config" {
  secret_id = data.aws_secretsmanager_secret.user_service.id
  secret_string = jsonencode(merge(
    jsondecode(data.aws_secretsmanager_secret_version.user_service_current.secret_string),
    {
      DB_URL      = "jdbc:postgresql://${split(":", aws_db_instance.main.endpoint)[0]}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}?sslmode=require"
      DB_USERNAME = aws_db_instance.main.username
      DB_PASSWORD = var.master_password
    }
  ))

  lifecycle {
    ignore_changes = [secret_string]
  }
}
