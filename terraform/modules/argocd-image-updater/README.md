# ArgoCD Image Updater Terraform Module

This module deploys ArgoCD Image Updater using Helm chart to automatically update container images in ArgoCD applications.

## Overview

ArgoCD Image Updater is a tool to automatically update the container images of Kubernetes workloads which are managed by ArgoCD. It works by monitoring container registries for new versions of images and updating the image tags in your Git repository or directly in the ArgoCD application.

## Features

- **Automatic Image Updates**: Monitors container registries and updates images when new versions are available
- **Multiple Registry Support**: Supports Docker Hub, ECR, GCR, and other container registries
- **Flexible Authentication**: Supports various authentication methods including IAM roles, service accounts, and scripts
- **Update Strategies**: Supports semantic versioning, date-based, and custom update strategies
- **Git Integration**: Can update image tags in Git repositories or directly in ArgoCD applications

## Usage

```hcl
module "argocd_image_updater" {
  source = "../../modules/argocd-image-updater"

  # Basic configuration
  release_name     = "argocd-image-updater"
  chart_version    = "0.11.0"
  namespace        = "argocd"

  # Registry configuration
  registries = [
    {
      name       = "ECR"
      api_url    = "https://182399707265.dkr.ecr.eu-west-1.amazonaws.com"
      prefix     = "182399707265.dkr.ecr.eu-west-1.amazonaws.com"
      ping       = true
      insecure   = false
      credentials = "ext:/scripts/auth.sh"
      credsexpire = "10h"
    }
  ]

  # Auth scripts for ECR
  auth_scripts = {
    "auth.sh" = <<-EOT
      #!/bin/sh
      aws ecr --region eu-west-1 get-authorization-token --output text --query 'authorizationData[].authorizationToken' | base64 -d
    EOT
  }

  tags = {
    Environment = "dev-staging"
    Project     = "cloudinsight"
  }
}
```

## How Image Updater Works with Multiple ECR Repositories

### 1. Registry Configuration

Configure a single ECR registry endpoint that covers all your repositories:

```yaml
config:
  registries:
    - name: ECR
      api_url: https://182399707265.dkr.ecr.eu-west-1.amazonaws.com
      prefix: 182399707265.dkr.ecr.eu-west-1.amazonaws.com
      ping: yes
      insecure: no
      credentials: ext:/scripts/auth.sh
      credsexpire: 10h
```

### 2. Application-Level Configuration

Each ArgoCD Application specifies which images to monitor via annotations:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cloudinsight-user-service
  annotations:
    # Monitor this image for updates
    argocd-image-updater.argoproj.io/image-list: user-service=182399707265.dkr.ecr.eu-west-1.amazonaws.com/cloudinsight-user-service
    # Update strategy (semantic versioning)
    argocd-image-updater.argoproj.io/user-service.update-strategy: semver
    # Allow updates to minor and patch versions
    argocd-image-updater.argoproj.io/user-service.allow-tags: regexp:^v[0-9]+\.[0-9]+\.[0-9]+$
spec:
  # ... rest of application spec
```

### 3. Automatic Discovery

Image Updater automatically:

- Scans all ArgoCD Applications for image update annotations
- Monitors the specified ECR repositories for new image tags
- Updates applications when new versions match the update strategy
- Syncs the applications to deploy the updated images

## Authentication Methods

### ECR Authentication with IAM Roles

The module supports ECR authentication through:

1. **Auth Scripts**: Custom shell scripts for dynamic token generation
2. **IAM Roles**: Using EKS Pod Identity or IRSA for automatic authentication

## Configuration Options

### Registry Configuration

- **api_url**: The API endpoint for the registry
- **prefix**: The prefix to match image names
- **credentials**: Authentication method (ext:/scripts/auth.sh for script-based auth)
- **credsexpire**: How long credentials are valid

### Update Strategies

- **semver**: Semantic versioning (e.g., v1.2.3)
- **latest**: Always use the latest tag
- **digest**: Use image digests for immutable updates
- **name**: Alphabetical sorting of tag names

### Auth Scripts

Custom shell scripts for authentication (useful for ECR):

```bash
#!/bin/sh
aws ecr --region eu-west-1 get-authorization-token --output text --query 'authorizationData[].authorizationToken' | base64 -d
```

## Variables

| Name                 | Description                         | Type          | Default                  | Required |
| -------------------- | ----------------------------------- | ------------- | ------------------------ | :------: |
| release_name         | The name of the Helm release        | `string`      | `"argocd-image-updater"` |    no    |
| chart_version        | The version of the Helm chart       | `string`      | `"0.11.0"`               |    no    |
| namespace            | The namespace for deployment        | `string`      | `"argocd"`               |    no    |
| registries           | List of registry configurations     | `list(any)`   | `[]`                     |   yes    |
| auth_scripts         | Map of auth script names to content | `map(string)` | `{}`                     |    no    |
| service_account_name | Name of the service account         | `string`      | `"argocd-image-updater"` |    no    |
| log_level            | Log level for the application       | `string`      | `"info"`                 |    no    |

## Outputs

| Name                 | Description                    |
| -------------------- | ------------------------------ |
| release_name         | The name of the Helm release   |
| namespace            | The namespace where deployed   |
| chart_version        | The chart version deployed     |
| service_account_name | The service account name       |
| status               | The status of the Helm release |

## Dependencies

- ArgoCD must be deployed first
- EKS cluster with proper IAM permissions for ECR access
- Helm provider configured

## Examples

See the `terraform/envs/dev-staging/argocd-image-updater/` directory for a complete example of how to use this module with ECR integration and IAM authentication.
