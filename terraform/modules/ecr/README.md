# CloudInsight ECR Module

This module creates and manages Amazon Elastic Container Registry (ECR) repositories for the CloudInsight project services.

## Features

- ✅ Creates private ECR repositories for all CloudInsight services
- ✅ Enables image scanning on push for security
- ✅ Implements lifecycle policies for image management
- ✅ Applies consistent tagging strategy
- ✅ Configures encryption at rest (AES256)
- ✅ Sets up repository policies for controlled access
- ✅ Separates frontend and backend repositories

## Repository List

This module creates ECR repositories for the following services:

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

## Usage

```hcl
module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment

  # Optional: Override default repositories
  repositories = [
    {
      name = "cloudinsight-frontend"
      type = "frontend"
    },
    {
      name = "cloudinsight-api-gateway"
      type = "backend"
    }
    # ... add more as needed
  ]

  # Optional: Configure image settings
  image_tag_mutability = "MUTABLE"  # or "IMMUTABLE"
  scan_on_push        = true

  tags = var.tags
}
```

## Lifecycle Policy

The module applies an optimized lifecycle policy designed for the CloudInsight tagging strategy:

### Retention Rules

- **Production releases** (`v*.*.0` format like `v0.1.0`): Keep last 20 versions
- **Release candidates** (`v*-rc.*` format like `v0.0.0-rc.1`): Keep last 10 versions
- **Development builds** (`v*-dev.*` format like `v0.0.0-dev.1`): Keep last 5 versions
- **Untagged images**: Deleted after 1 day

### Tagging Strategy Compatibility

This policy is optimized for the following tag patterns:

- Development: `v0.0.0-dev.1`, `v0.0.0-dev.2`, etc.
- Release Candidates: `v0.0.0-rc.1`, `v0.0.0-rc.2`, etc.
- Production: `v0.1.0`, `v0.2.0`, etc.

You can override this by providing a custom `lifecycle_policy` variable.

## Outputs

- `repository_urls`: Map of repository names to their URLs
- `repository_arns`: Map of repository names to their ARNs
- `repository_names`: List of all repository names
- `frontend_repositories`: URLs of frontend repositories only
- `backend_repositories`: URLs of backend repositories only

## Security Features

- **Encryption**: All repositories use AES256 encryption at rest
- **Image Scanning**: Automatic vulnerability scanning on image push
- **Access Control**: Repository policies restrict access to project resources
- **Lifecycle Management**: Automatic cleanup of old and untagged images

## Integration with EKS

This module works seamlessly with the existing EKS module, which already has ECR read permissions configured for the worker nodes.

## Cost Optimization

- Lifecycle policies automatically clean up unused images
- Only essential repositories are created
- Storage costs are minimized through image retention policies
