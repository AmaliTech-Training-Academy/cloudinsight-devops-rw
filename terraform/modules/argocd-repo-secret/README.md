# ArgoCD Repository Secret Module

This module creates Kubernetes secrets for ArgoCD to access private Git repositories. The module securely retrieves SSH private keys from AWS Secrets Manager using EKS Pod Identity authentication.

## Overview

This module creates a properly formatted Kubernetes secret that ArgoCD can use to access private Git repositories via SSH. The SSH private key is retrieved from AWS Secrets Manager using EKS Pod Identity, ensuring secure access without hardcoded credentials.

## Features

- ✅ **Secure Secret Retrieval**: Pulls SSH private keys from AWS Secrets Manager
- ✅ **EKS Pod Identity Integration**: Uses Pod Identity for secure AWS authentication  
- ✅ **ArgoCD Compatible**: Creates secrets in the exact format required by ArgoCD
- ✅ **Configurable**: Support for custom namespaces, secret names, and labels
- ✅ **Validation**: Input validation for repository URLs and secret names
- ✅ **Reusable**: Generic module for multiple repositories and environments

## Usage

```hcl
module "argocd_private_repo_secret" {
  source = "../../modules/argocd-repo-secret"
  
  cluster_name   = "my-eks-cluster"
  aws_region     = "us-west-2"
  repository_url = "git@github.com:company/private-repo.git"
  
  # Optional: Override defaults
  secret_name             = "argocd-private-key"
  namespace               = "argocd"
  kubernetes_secret_name  = "private-repo-secret"
  
  secret_labels = {
    environment = "dev-staging"
    managed-by  = "terraform"
    repository  = "private-repo"
  }
  
  tags = {
    Environment = "dev-staging"
    ManagedBy   = "Terraform"
    Purpose     = "ArgoCD repository access"
  }
}
```

## Prerequisites

### 1. AWS Secrets Manager Secret

Create a secret in AWS Secrets Manager containing the SSH private key:

```bash
# Create the secret (store as plaintext, not key/value)
aws secretsmanager create-secret \
  --name "argocd-private-key" \
  --description "SSH private key for ArgoCD repository access" \
  --secret-string "$(cat ~/.ssh/id_rsa)"
```

### 2. IAM Role and Pod Identity

The module requires an IAM role with Pod Identity associations. Use the existing `secrets-access-iam` and `pod-identity-secrets` modules:

```hcl
# Create IAM role with secrets access
module "argocd_secrets_iam" {
  source = "../../modules/secrets-access-iam"
  
  cluster_name = var.cluster_name
  services = [
    {
      name        = "argocd"
      secret_name = "argocd-private-key"
    }
  ]
  
  tags = var.tags
}

# Create Pod Identity association
module "argocd_pod_identity" {
  source = "../../modules/pod-identity-secrets"
  
  cluster_name = var.cluster_name
  microservices = [
    {
      name            = "argocd-repo-server"
      namespace       = "argocd"
      service_account = "argocd-repo-server"
      role_arn        = module.argocd_secrets_iam.service_role_arns["argocd"]
    }
  ]
  
  tags = var.tags
}
```

### 3. Required IAM Permissions

The IAM role needs the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:argocd-private-key*"
    }
  ]
}
```

## ArgoCD Secret Format

The module creates a Kubernetes secret in the exact format required by ArgoCD:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: private-repo-secret
  namespace: argocd
  annotations:
    argocd.argoproj.io/secret-type: repository
  labels:
    argocd.argoproj.io/secret-type: repository
    app.kubernetes.io/name: argocd
    app.kubernetes.io/component: repository-secret
    app.kubernetes.io/managed-by: terraform
type: Opaque
data:
  type: git
  url: <repository-url>
  sshPrivateKey: <base64-encoded-private-key>
```

## Security Considerations

### Secret Handling
- SSH private key is retrieved securely from AWS Secrets Manager
- Key is base64 encoded for Kubernetes secret storage
- No private key material is stored in Terraform state as plaintext
- Use `sensitive = true` for outputs containing secret ARNs

### Access Control
- Uses EKS Pod Identity for secure AWS authentication
- IAM role follows principle of least privilege
- Access is restricted to specific secrets by ARN pattern

### Best Practices
- Rotate SSH keys regularly
- Monitor secret access via CloudTrail
- Use separate secrets for different environments
- Consider using GitHub Deploy Keys for repository-specific access

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | EKS cluster name | `string` | n/a | yes |
| aws_region | AWS region where the secret is stored | `string` | `"us-west-2"` | no |
| secret_name | Name of the AWS Secrets Manager secret | `string` | `"argocd-private-key"` | no |
| repository_url | Git repository URL (SSH format) | `string` | n/a | yes |
| secret_labels | Additional labels for the Kubernetes secret | `map(string)` | `{}` | no |
| namespace | Kubernetes namespace for the secret | `string` | `"argocd"` | no |
| kubernetes_secret_name | Name of the Kubernetes secret to create | `string` | `"private-repo-secret"` | no |
| tags | Tags to apply to AWS resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| secret_name | Name of the created Kubernetes secret | no |
| secret_namespace | Namespace of the created secret | no |
| secret_uid | UID of the created secret | no |
| repository_url | Git repository URL configured in the secret | no |
| aws_secret_arn | ARN of the AWS Secrets Manager secret | yes |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | ~> 5.0 |
| kubernetes | ~> 2.23 |

## Resources Created

- `kubernetes_secret.argocd_repo_secret` - Kubernetes secret with repository credentials

## Data Sources Used

- `aws_secretsmanager_secret.argocd_private_key` - AWS Secrets Manager secret metadata
- `aws_secretsmanager_secret_version.argocd_private_key` - SSH private key content
- `aws_caller_identity.current` - Current AWS account information
- `aws_region.current` - Current AWS region

## Testing

After applying the module, verify the secret was created correctly:

```bash
# Check if secret exists
kubectl get secret private-repo-secret -n argocd

# Verify secret labels and annotations
kubectl describe secret private-repo-secret -n argocd

# Test ArgoCD repository access (from ArgoCD UI or CLI)
argocd repo add git@github.com:company/private-repo.git --ssh-private-key-path /dev/null
```

## Troubleshooting

### Common Issues

1. **Secret not found in AWS Secrets Manager**
   ```
   Error: reading Secrets Manager Secret Version
   ```
   - Verify the secret exists: `aws secretsmanager describe-secret --secret-id argocd-private-key`
   - Check the secret name matches the `secret_name` variable

2. **Permission denied accessing secret**
   ```
   Error: AccessDeniedException
   ```
   - Verify IAM role has `secretsmanager:GetSecretValue` permission
   - Check Pod Identity association is configured correctly
   - Ensure the secret ARN pattern matches the IAM policy

3. **ArgoCD cannot access repository**
   - Verify the SSH key format is correct (OpenSSH format)
   - Check the repository URL uses SSH format (`git@...`)
   - Ensure the public key is added to the Git provider (GitHub, GitLab, etc.)

### Debug Commands

```bash
# Check Pod Identity associations
aws eks list-pod-identity-associations --cluster-name <cluster-name>

# Verify secret content (be careful with sensitive data)
kubectl get secret private-repo-secret -n argocd -o yaml

# Test AWS access from a pod
kubectl run test-pod --image=amazon/aws-cli:latest --rm -it -- \
  aws secretsmanager get-secret-value --secret-id argocd-private-key
```

## Examples

### Multiple Repositories

```hcl
# Repository 1
module "repo_1_secret" {
  source = "../../modules/argocd-repo-secret"
  
  cluster_name   = var.cluster_name
  repository_url = "git@github.com:company/repo-1.git"
  secret_name    = "argocd-repo-1-key"
  kubernetes_secret_name = "repo-1-secret"
}

# Repository 2  
module "repo_2_secret" {
  source = "../../modules/argocd-repo-secret"
  
  cluster_name   = var.cluster_name
  repository_url = "git@github.com:company/repo-2.git"
  secret_name    = "argocd-repo-2-key"
  kubernetes_secret_name = "repo-2-secret"
}
```

### Different Environments

```hcl
# Development environment
module "dev_repo_secret" {
  source = "../../modules/argocd-repo-secret"
  
  cluster_name   = "dev-cluster"
  repository_url = "git@github.com:company/app-configs-dev.git"
  secret_name    = "dev-argocd-private-key"
  
  secret_labels = {
    environment = "development"
  }
}

# Production environment
module "prod_repo_secret" {
  source = "../../modules/argocd-repo-secret"
  
  cluster_name   = "prod-cluster"
  repository_url = "git@github.com:company/app-configs-prod.git"
  secret_name    = "prod-argocd-private-key"
  
  secret_labels = {
    environment = "production"
  }
}
```

## Related Modules

- [`secrets-access-iam`](../secrets-access-iam/) - Creates IAM roles for accessing AWS Secrets Manager
- [`pod-identity-secrets`](../pod-identity-secrets/) - Creates Pod Identity associations
- [`argocd`](../argocd/) - Deploys ArgoCD on EKS cluster
- [`secrets-csi-driver`](../secrets-csi-driver/) - Installs Secrets Store CSI Driver (not used by this module)

## Contributing

When contributing to this module:

1. Follow the existing code style and patterns
2. Update documentation for any new variables or outputs
3. Add validation rules for new variables where appropriate
4. Test the module in a real environment before submitting
5. Update examples if the module interface changes