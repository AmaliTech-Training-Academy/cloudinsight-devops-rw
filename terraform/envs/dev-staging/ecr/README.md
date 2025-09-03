# ECR Infrastructure - Development/Staging Environment

This directory contains the Terraform configuration for creating ECR (Elastic Container Registry) repositories for the CloudInsight project in the development/staging environment.

## Overview

This configuration uses the ECR module to create private Docker repositories for all CloudInsight services:

### Frontend Services

- `cloudinsight-frontend`

### Backend Services

- `cloudinsight-api-gateway`
- `cloudinsight-service-discovery`
- `cloudinsight-config-server`
- `cloudinsight-user-service`
- `cloudinsight-cost-service`
- `cloudinsight-metric-service`
- `cloudinsight-anomaly-service`
- `cloudinsight-forecast-service`
- `cloudinsight-notification-service`

## Quick Start

1. **Initialize Terraform:**

   ```bash
   terraform init -backend-config=backend.hcl
   ```

2. **Plan the deployment:**

   ```bash
   terraform plan -var-file=terraform.tfvars
   ```

3. **Apply the configuration:**
   ```bash
   terraform apply -var-file=terraform.tfvars -auto-approve
   ```

## Features

- ✅ Creates private ECR repositories for all services
- ✅ Enables image vulnerability scanning
- ✅ Implements lifecycle policies for cost optimization
- ✅ Applies consistent tagging strategy
- ✅ Configures encryption at rest
- ✅ Sets up repository access policies

## Outputs

After deployment, you'll get:

- Repository URLs for Docker push/pull operations
- Repository ARNs for IAM policy references
- Separate outputs for frontend and backend repositories

## Usage in CI/CD

The created repositories can be used in your CI/CD pipelines:

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and tag your image
docker build -t cloudinsight-frontend .
docker tag cloudinsight-frontend:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/cloudinsight-frontend:latest

# Push to ECR
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/cloudinsight-frontend:latest
```

## Cost Optimization

The repositories include lifecycle policies that:

- Keep only the last 10 tagged images
- Remove untagged images after 1 day
- Help minimize storage costs

## Integration

This ECR configuration works with:

- The existing EKS cluster (nodes have ECR read permissions)
- CI/CD pipelines for automated image builds and deployments
- Container security scanning and vulnerability management
