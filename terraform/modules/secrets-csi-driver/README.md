# Secrets Store CSI Driver Module

This module installs the Secrets Store CSI Driver and AWS Secrets Manager provider on an EKS cluster.

## Overview

The Secrets Store CSI Driver allows Kubernetes to mount secrets from external secret stores (like AWS Secrets Manager) as volumes in pods. This module installs:

1. **Secrets Store CSI Driver**: Core driver that provides the CSI interface
2. **AWS Secrets Manager CSI Provider**: Provider that connects to AWS Secrets Manager

## Features

- ✅ **Secret Syncing**: Automatically sync secrets to Kubernetes secrets
- ✅ **Secret Rotation**: Automatic secret rotation support
- ✅ **Cluster-wide Installation**: Installs in `kube-system` namespace
- ✅ **Configurable Versions**: Control Helm chart versions
- ✅ **Dependency Management**: Proper installation order

## Usage

```hcl
module "secrets_csi_driver" {
  source = "../../modules/secrets-csi-driver"

  # Optional: Override default versions
  csi_driver_version    = "1.4.6"
  aws_provider_version  = "0.3.9"

  # Optional: Configure secret sync and rotation
  sync_secret_enabled    = true
  enable_secret_rotation = true
  rotation_poll_interval = "2m"

  tags = {
    Environment = "dev-staging"
    ManagedBy   = "Terraform"
  }
}
```

## Requirements

- EKS cluster with Kubernetes 1.19+
- Helm provider configured
- Kubernetes provider configured

## Resources Created

- `helm_release.secrets_csi_driver` - Main CSI driver
- `helm_release.secrets_csi_driver_aws_provider` - AWS provider

## Verification

After installation, verify the drivers are running:

```bash
kubectl get pods -n kube-system -l app=secrets-store-csi-driver
kubectl get pods -n kube-system -l app=csi-secrets-store-provider-aws
```

## Next Steps

After installing the CSI driver, you'll need:

1. IAM roles for secrets access (see `secrets-access-iam` module)
2. Pod Identity associations (see `pod-identity-secrets` module)
3. SecretProviderClass resources in your application namespaces
