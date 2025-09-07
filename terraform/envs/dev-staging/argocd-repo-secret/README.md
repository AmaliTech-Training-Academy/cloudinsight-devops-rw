# ArgoCD Repository Secret - Dev/Staging Environment

This directory contains the Terraform configuration for deploying the ArgoCD repository secret module in the dev-staging environment.

## Overview

This configuration creates a Kubernetes secret that allows ArgoCD to access private Git repositories using SSH authentication. The SSH private key is securely retrieved from AWS Secrets Manager using EKS Pod Identity.

## Prerequisites

Before deploying this configuration, ensure you have:

### 1. AWS Secrets Manager Secret

Create the SSH private key secret in AWS Secrets Manager:

```bash
# Generate SSH key pair (if you don't have one)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/argocd_key -N ""

# Create the secret in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "argocd-private-key" \
  --description "SSH private key for ArgoCD repository access" \
  --secret-string "$(cat ~/.ssh/argocd_key)"

# Add the public key to your Git provider (GitHub, GitLab, etc.)
cat ~/.ssh/argocd_key.pub
```

### 2. IAM Role and Pod Identity

Set up IAM permissions for ArgoCD to access the secret:

```hcl
# Create IAM role (use existing secrets-access-iam module)
module "argocd_secrets_iam" {
  source = "../../../modules/secrets-access-iam"
  
  cluster_name = "cloudinsight-dev-staging"
  services = [
    {
      name        = "argocd"
      secret_name = "argocd-private-key"
    }
  ]
  
  tags = {
    Environment = "dev-staging"
    Purpose     = "ArgoCD secrets access"
  }
}

# Create Pod Identity association (use existing pod-identity-secrets module)
module "argocd_pod_identity" {
  source = "../../../modules/pod-identity-secrets"
  
  cluster_name = "cloudinsight-dev-staging"
  microservices = [
    {
      name            = "argocd-repo-server"
      namespace       = "argocd"
      service_account = "argocd-repo-server"
      role_arn        = module.argocd_secrets_iam.service_role_arns["argocd"]
    }
  ]
  
  tags = {
    Environment = "dev-staging"
    Purpose     = "ArgoCD Pod Identity"
  }
}
```

### 3. EKS Cluster and ArgoCD

Ensure you have:
- EKS cluster running with Pod Identity addon enabled
- ArgoCD deployed in the cluster
- Proper kubeconfig context set

## Configuration

### Variables

The key variables for this deployment:

- `cluster_name`: EKS cluster name (default: "cloudinsight-dev-staging")
- `repository_url`: SSH URL of your private Git repository
- `secret_name`: Name of the AWS Secrets Manager secret (default: "argocd-private-key")
- `namespace`: Kubernetes namespace for ArgoCD (default: "argocd")

### Terraform Variables File

Review and update `terraform.tfvars` with your specific values:

```hcl
repository_url = "git@github.com:your-org/your-private-repo.git"
secret_name    = "your-secret-name"
cluster_name   = "your-cluster-name"
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

## Verification

After deployment, verify the secret was created correctly:

```bash
# Check if the secret exists
kubectl get secret private-repo-secret -n argocd

# Verify secret format and annotations
kubectl describe secret private-repo-secret -n argocd

# Check secret data (be careful with sensitive data)
kubectl get secret private-repo-secret -n argocd -o yaml
```

## Testing ArgoCD Repository Access

Test that ArgoCD can access your private repository:

1. **Add repository in ArgoCD UI**:
   - Go to Settings > Repositories
   - Add new repository with SSH URL
   - ArgoCD should automatically use the secret

2. **Via ArgoCD CLI**:
   ```bash
   # Login to ArgoCD
   argocd login <argocd-server>
   
   # Add repository
   argocd repo add git@github.com:your-org/your-private-repo.git
   
   # List repositories to verify
   argocd repo list
   ```

## Troubleshooting

### Common Issues

1. **Secret not found in AWS**:
   ```bash
   aws secretsmanager describe-secret --secret-id argocd-private-key
   ```

2. **Permission denied accessing secret**:
   - Check IAM role permissions
   - Verify Pod Identity association
   - Check service account in ArgoCD

3. **ArgoCD cannot access repository**:
   - Verify SSH key format
   - Check public key is added to Git provider
   - Test SSH connection from a pod

### Debug Commands

```bash
# Check Pod Identity associations
aws eks list-pod-identity-associations --cluster-name cloudinsight-dev-staging

# Test secret access from a pod
kubectl run debug-pod --image=amazon/aws-cli:latest --rm -it -- \
  aws secretsmanager get-secret-value --secret-id argocd-private-key

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-repo-server
```

## Files

- `main.tf`: Main Terraform configuration using the argocd-repo-secret module
- `variables.tf`: Variable definitions
- `outputs.tf`: Output definitions
- `terraform.tfvars`: Variable values for dev-staging environment
- `providers.tf`: Provider configuration
- `versions.tf`: Terraform and provider version constraints
- `backend.hcl`: Backend configuration for state storage

## Related Resources

- [ArgoCD Repository Secret Module](../../../modules/argocd-repo-secret/)
- [Secrets Access IAM Module](../../../modules/secrets-access-iam/)
- [Pod Identity Secrets Module](../../../modules/pod-identity-secrets/)

## Security Notes

- Never commit SSH private keys to version control
- Use separate SSH keys for different environments
- Regularly rotate SSH keys
- Monitor secret access via CloudTrail
- Follow principle of least privilege for IAM roles