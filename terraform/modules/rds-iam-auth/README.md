# RDS IAM Authentication Module

This module creates an Amazon RDS PostgreSQL instance with IAM database authentication enabled, along with the necessary IAM roles and policies for EKS Pod Identity integration.

## Features

- RDS PostgreSQL with IAM authentication enabled
- Automatic IAM role creation for database access
- EKS Pod Identity association
- Security group with restricted access
- Optional enhanced monitoring
- Configurable backup and maintenance windows
- Support for multiple IAM database users

## Usage

```hcl
module "rds_iam_auth" {
  source = "../../modules/rds-iam-auth"
  
  cluster_name                = "cloudinsight"
  environment                = "dev-staging"
  vpc_id                     = "vpc-12345678"
  private_subnet_ids         = ["subnet-12345", "subnet-67890"]
  eks_node_security_group_ids = ["sg-12345678"]
  
  master_password = var.db_password
  
  iam_database_users = ["myapp_user"]
  
  common_tags = {
    Environment = "dev-staging"
    Project     = "cloudinsight"
    Module      = "rds-iam-auth"
  }
}
```

## Database User Setup

After deployment, run the database initialization job to create IAM users:

```sql
-- Connect as master user
CREATE USER myapp_user;
GRANT rds_iam TO myapp_user;
GRANT CONNECT ON DATABASE myapp TO myapp_user;
-- Additional permissions as needed
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | ~> 5.0 |
| kubernetes | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| aws_db_instance.main | resource |
| aws_db_subnet_group.main | resource |
| aws_security_group.rds | resource |
| aws_iam_role.db_access | resource |
| aws_iam_role_policy.db_access | resource |
| aws_iam_role.rds_monitoring | resource |
| aws_iam_role_policy_attachment.rds_monitoring | resource |
| aws_eks_pod_identity_association.db_access | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| vpc_id | VPC ID where RDS will be deployed | `string` | n/a | yes |
| private_subnet_ids | List of private subnet IDs for RDS | `list(string)` | n/a | yes |
| eks_node_security_group_ids | List of EKS node security group IDs | `list(string)` | n/a | yes |
| master_password | Master password for the database | `string` | n/a | yes |
| database_name | Name of the database to create | `string` | `"myapp"` | no |
| master_username | Master username for the database | `string` | `"postgres"` | no |
| postgres_version | PostgreSQL version | `string` | `"15.4"` | no |
| instance_class | RDS instance class | `string` | `"db.t3.micro"` | no |
| iam_database_users | List of IAM database users to create permissions for | `list(string)` | `["myapp_user"]` | no |
| common_tags | Common tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| rds_instance_id | RDS instance identifier |
| rds_endpoint | RDS instance endpoint |
| rds_port | RDS instance port |
| database_name | Database name |
| iam_role_arn | ARN of the IAM role for database access |
| configmap_data | Data for Kubernetes ConfigMap (non-sensitive values) |
| db_user_arns | ARNs of the IAM database users |

The module outputs database connection information suitable for Kubernetes ConfigMaps.