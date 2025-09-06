# RDS with IAM Authentication - Dev Staging Environment

This directory deploys the RDS IAM Authentication module to the dev-staging environment.

## Overview

Deploys:
- RDS PostgreSQL instance with IAM authentication enabled
- IAM roles and policies for database access
- EKS Pod Identity associations
- Kubernetes ConfigMap with database connection information

## Usage

```bash
# Initialize and deploy
terraform init -backend-config=backend.hcl
terraform plan -var="master_password=YOUR_SECURE_PASSWORD"
terraform apply -var="master_password=YOUR_SECURE_PASSWORD"

# Verify ConfigMap creation
kubectl get configmap cloudinsight-db-config -o yaml
```

## Dependencies

- VPC and networking (from networking module)
- EKS cluster (from eks module) 
- Proper AWS credentials and region configuration

## Configuration

The `terraform.tfvars` file contains environment-specific settings including:
- Database instance configuration
- Storage and backup settings
- IAM database users
- Kubernetes namespace and service account

## Outputs

- Database connection information
- IAM role ARNs
- ConfigMap name for application use

## Security

- RDS is deployed in private subnets only
- Security groups restrict access to EKS nodes
- IAM authentication replaces traditional passwords
- Pod Identity provides secure credential access