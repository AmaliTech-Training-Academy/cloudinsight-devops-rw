# Pod Identity Secrets Module

This module creates EKS Pod Identity associations to link Kubernetes service accounts with IAM roles for AWS Secrets Manager access.

## Overview

This module creates Pod Identity associations that allow Kubernetes pods to assume IAM roles for accessing AWS Secrets Manager. It only handles the associations - the IAM roles should be created separately using the `secrets-access-iam` module.

## Features

- ✅ **Pod Identity Associations**: Links service accounts to IAM roles
- ✅ **Multiple Microservices**: Support for multiple services in one configuration
- ✅ **Simple and Focused**: Only handles Pod Identity associations
- ✅ **Verification Commands**: Built-in commands to test the setup

## Usage

```hcl
module "pod_identity_secrets" {
  source = "../../modules/pod-identity-secrets"

  cluster_name      = "my-eks-cluster"
  secrets_role_arn  = module.secrets_iam.role_arn

  microservices = [
    {
      name            = "user-service"
      namespace       = "user-service"
      service_account = "user-service-sa"
    },
    {
      name            = "order-service"
      namespace       = "order-service"
      service_account = "order-service-sa"
    }
  ]

  tags = {
    Environment = "dev-staging"
    ManagedBy   = "Terraform"
  }
}
```

## CloudInsight Example

For the CloudInsight project with all 10 microservices:

```hcl
microservices = [
  { name = "user-service",         namespace = "user-service",         service_account = "user-service-sa" },
  { name = "auth-service",         namespace = "auth-service",         service_account = "auth-service-sa" },
  { name = "profile-service",      namespace = "profile-service",      service_account = "profile-service-sa" },
  { name = "project-service",      namespace = "project-service",      service_account = "project-service-sa" },
  { name = "monitoring-service",   namespace = "monitoring-service",   service_account = "monitoring-service-sa" },
  { name = "analytics-service",    namespace = "analytics-service",    service_account = "analytics-service-sa" },
  { name = "notification-service", namespace = "notification-service", service_account = "notification-service-sa" },
  { name = "file-service",         namespace = "file-service",         service_account = "file-service-sa" },
  { name = "gateway-service",      namespace = "gateway-service",      service_account = "gateway-service-sa" },
  { name = "admin-service",        namespace = "admin-service",        service_account = "admin-service-sa" }
]
```

## Requirements

- EKS cluster with Pod Identity addon enabled
- IAM role created (from `secrets-access-iam` module)
- AWS provider configured

## Resources Created

- `aws_eks_pod_identity_association.microservices` - Pod Identity associations

## Dependencies

This module depends on:

- `secrets-access-iam` module (provides the IAM role ARN)
- `secrets-csi-driver` module (provides the CSI driver for mounting secrets)

## Verification

After applying, use the verification commands from the module output to test the setup.

## How Pod Identity Works

1. **Association Creation**: Links a namespace/service account to an IAM role
2. **Pod Startup**: When a pod uses the specified service account, EKS injects AWS credentials
3. **Automatic Authentication**: The pod can access AWS services without manual credential management
4. **CSI Driver Integration**: CSI driver uses these injected credentials to fetch secrets

## Next Steps

After creating Pod Identity associations:

1. Create SecretProviderClass resources in your application namespaces
2. Configure your pod specifications to mount secrets using the CSI driver
3. Update your application deployments to use the configured service accounts
