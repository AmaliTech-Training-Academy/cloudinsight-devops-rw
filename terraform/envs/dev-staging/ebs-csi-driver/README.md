# EBS CSI Driver - Dev-Staging Environment

This directory contains the Terraform configuration for deploying the AWS EBS CSI driver addon to the dev-staging EKS cluster.

## Overview

The EBS CSI driver enables dynamic provisioning of EBS volumes for Kubernetes persistent volumes. This deployment uses Pod Identity for authentication, which requires the Pod Identity agent to be deployed in the cluster.

## Prerequisites

- EKS cluster deployed (from `../eks/`)
- Pod Identity agent deployed (from `../pod-identity-agent/`)
- Terraform backend configured
- AWS credentials configured

## Deployment

1. Initialize Terraform:

```bash
terraform init -backend-config=backend.hcl
```

2. Plan the deployment:

```bash
terraform plan
```

3. Apply the configuration:

```bash
terraform apply
```

## Features

- AWS EBS CSI driver addon deployed as an EKS addon
- IAM role with necessary permissions for EBS operations
- Pod Identity association for secure authentication
- Optional EBS encryption support (enabled by default)
- Configurable addon version and conflict resolution

## Outputs

The deployment provides several outputs including:

- EBS CSI driver IAM role ARN
- Addon name and version
- Pod Identity association ID
- Service account details

## Testing

After deployment, you can test the EBS CSI driver by creating a persistent volume claim:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: gp3
```

## Configuration

Key configuration values are set in `terraform.tfvars`:

- `addon_version`: Version of the EBS CSI driver
- `enable_encryption`: Whether to enable EBS encryption support
- `namespace`: Kubernetes namespace (default: kube-system)
- `service_account_name`: Service account name (default: ebs-csi-controller-sa)
