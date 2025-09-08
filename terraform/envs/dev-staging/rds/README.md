# RDS with IAM Authentication - Dev/Staging Environment

This Terraform configuration deploys an RDS PostgreSQL instance with IAM authentication for the CloudInsight dev-staging environment. It uses remote state to fetch outputs from the networking and EKS modules.

## Features

- **Password-less Authentication**: Uses AWS managed master user password by default
- **IAM Database Authentication**: Enables secure database access via IAM roles
- **EKS Integration**: Automatically configures access for EKS worker nodes
- **Remote State Integration**: Fetches VPC, subnets, and security groups from other modules
- **Kubernetes ConfigMap**: Automatically creates ConfigMap with database connection details

## Dependencies

This module depends on the following infrastructure:

1. **Networking Module**: Provides VPC and subnet information
2. **EKS Module**: Provides cluster information and security groups

## Remote State Dependencies

```hcl
# Networking outputs used:
- vpc_id
- private_subnet_ids

# EKS outputs used:
- cluster_name
- cluster_endpoint
- cluster_certificate_authority_data
- cluster_security_group_id
```

## Configuration

### Default (Recommended): AWS Managed Password

```hcl
manage_master_user_password = true  # Default
master_password            = null   # Not used
```

### Alternative: Custom Password

```hcl
manage_master_user_password = false
master_password            = "your-secure-password"
```

## Deployment

1. **Initialize Terraform**:

   ```bash
   terraform init -backend-config=backend.hcl
   ```

2. **Plan the deployment**:

   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Outputs

- `rds_instance_id`: RDS instance identifier
- `rds_endpoint`: Database connection endpoint
- `database_name`: Name of the database
- `iam_role_arn`: IAM role ARN for database access
- `master_user_secret_arn`: ARN of the master password secret (when using AWS managed password)
- `configmap_name`: Name of the Kubernetes ConfigMap with database configuration
- `db_user_arns`: ARNs of IAM database users

## Security

- Database is deployed in private subnets only
- Security group restricts access to EKS nodes
- IAM authentication eliminates the need for password storage
- AWS Secrets Manager handles master password securely

## Cost Optimization (Dev/Staging)

- Performance Insights disabled
- Enhanced monitoring disabled
- Smaller instance class (db.t3.micro)
- Reduced backup retention (3 days)
- Skip final snapshot enabled

## IAM Database Users

Default users created for IAM authentication:

- `cloudinsight_user`: Main application user
- `readonly_user`: Read-only access user

## Kubernetes Integration

A ConfigMap is automatically created with the following data:

- `DB_HOST`: Database endpoint
- `DB_PORT`: Database port
- `DB_NAME`: Database name
- `DB_USERNAME`: IAM database user
- `USE_IAM_AUTH`: Set to "true"
- `IAM_ROLE_ARN`: IAM role ARN for database access

## Notes

- Ensure networking and EKS modules are deployed first
- The database will be accessible only from within the EKS cluster
- Applications must use IAM authentication instead of passwords
- Master password is managed by AWS Secrets Manager when using the default configuration
