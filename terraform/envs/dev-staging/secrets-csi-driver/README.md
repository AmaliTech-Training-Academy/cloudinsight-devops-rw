# Secrets CSI Driver - Dev Staging Environment

This environment deploys the Secrets Store CSI Driver and AWS Secrets Manager provider to the EKS cluster.

## Overview

This configuration deploys:

- Secrets Store CSI Driver (v1.4.6)
- AWS Secrets Manager CSI Provider (v0.3.9)

## Features Enabled

- ✅ Secret syncing to Kubernetes secrets
- ✅ Automatic secret rotation (2m interval)
- ✅ Cluster-wide deployment in kube-system namespace

## Usage

```bash
# Initialize and deploy
terraform init -backend-config=backend.hcl
terraform plan
terraform apply

# Verify deployment
kubectl get pods -n kube-system -l app=secrets-store-csi-driver
kubectl get daemonset -n kube-system | grep secrets
```

## Dependencies

- EKS cluster (from eks module)
- Proper AWS credentials and region configuration

## Next Steps

After deploying this module, you can deploy:

1. `secrets-access-iam` - IAM roles for secret access
2. `pod-identity-secrets` - Pod Identity associations
3. Application-specific SecretProviderClass resources
