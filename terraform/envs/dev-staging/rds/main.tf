# Data sources for existing infrastructure
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket  = "cloudinsight-tfstate"
    key     = "dev-staging/networking.tfstate"
    region  = var.aws_region
    encrypt = true
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket  = "cloudinsight-tfstate"
    key     = "dev-staging/eks.tfstate"
    region  = var.aws_region
    encrypt = true
  }
}

# Data source to get EKS node security groups (EKS creates these automatically)
data "aws_security_groups" "eks_node_groups" {
  filter {
    name   = "group-name"
    values = ["*${data.terraform_remote_state.eks.outputs.cluster_name}*node*"]
  }

  filter {
    name   = "vpc-id"
    values = [data.terraform_remote_state.networking.outputs.vpc_id]
  }
}

# RDS Module with Traditional Authentication
module "rds_iam_auth" {
  source = "../../../modules/rds-iam-auth"

  # Required Configuration
  cluster_name       = data.terraform_remote_state.eks.outputs.cluster_name
  environment        = var.environment
  vpc_id             = data.terraform_remote_state.networking.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids
  eks_node_security_group_ids = concat(
    [data.terraform_remote_state.eks.outputs.cluster_security_group_id],
    data.aws_security_groups.eks_node_groups.ids
  )

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

  # EKS Pod Identity for Secrets Manager access
  create_pod_identity_association = true
  kubernetes_namespace            = "user-service-dev"
  kubernetes_service_account      = "user-service-sa"

  # Tags
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Module      = "rds-iam-auth"
    ManagedBy   = "terraform"
    Stack       = "rds"
  }
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "db_config" {
  metadata {
    name      = "${var.project_name}-db-config"
    namespace = "user-service-dev"

    labels = {
      "app.kubernetes.io/name"       = "${var.project_name}-db-config"
      "app.kubernetes.io/component"  = "database"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = module.rds_iam_auth.configmap_data
}
