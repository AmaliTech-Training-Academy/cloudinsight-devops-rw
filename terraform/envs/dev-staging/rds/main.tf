# Data sources for existing infrastructure
data "aws_vpc" "main" {
  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  tags = {
    Tier = "private"
  }
}

data "aws_security_groups" "eks_nodes" {
  filter {
    name   = "group-name"
    values = ["${var.project_name}-${var.environment}-node-*"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# RDS with IAM Authentication Module
module "rds_iam_auth" {
  source = "../../../modules/rds-iam-auth"

  # Required Configuration
  cluster_name                = "${var.project_name}-${var.environment}"
  environment                 = var.environment
  vpc_id                      = data.aws_vpc.main.id
  private_subnet_ids          = data.aws_subnets.private.ids
  eks_node_security_group_ids = data.aws_security_groups.eks_nodes.ids

  # Database Configuration
  database_name    = var.database_name
  master_username  = var.master_username
  master_password  = var.master_password
  postgres_version = var.postgres_version
  instance_class   = var.instance_class

  # Storage Configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = var.storage_encrypted

  # Backup Configuration
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot

  # Monitoring
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval          = var.monitoring_interval

  # IAM Database Users
  iam_database_users = var.iam_database_users

  # EKS Integration
  kubernetes_namespace       = var.kubernetes_namespace
  kubernetes_service_account = var.kubernetes_service_account

  # Tags
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Module      = "rds-iam-auth"
  }
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "db_config" {
  metadata {
    name      = "${var.project_name}-db-config"
    namespace = var.kubernetes_namespace

    labels = {
      "app.kubernetes.io/name"       = "${var.project_name}-db-config"
      "app.kubernetes.io/component"  = "database"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = module.rds_iam_auth.configmap_data
}