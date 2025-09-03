# Secrets Access IAM Module

This module creates IAM roles and policies for accessing AWS Secrets Manager from EKS pods using Pod Identity.

## Overview

This module creates the necessary IAM resources for EKS pods to access AWS Secrets Manager:

1. **IAM Role**: With Pod Identity trust policy (not IRSA)
2. **IAM Policy**: With permissions to access specified secrets
3. **Policy Attachment**: Links the policy to the role

## Features

- ✅ **Pod Identity Support**: Uses new EKS Pod Identity (not IRSA)
- ✅ **Configurable Access**: Control which secrets can be accessed
- ✅ **Secure by Default**: Follows AWS security best practices
- ✅ **Flexible Patterns**: Support ARN patterns for secret access
- ✅ **Tagging Support**: Apply custom tags to all resources

## Usage

```hcl
module "secrets_iam" {
  source = "../../modules/secrets-access-iam"

  cluster_name = "my-eks-cluster"

  # Restrict access to specific secret patterns
  allowed_secret_patterns = [
    "arn:aws:secretsmanager:us-west-2:123456789012:secret:cloudinsight/*",
    "arn:aws:secretsmanager:us-west-2:123456789012:secret:app-config/*"
  ]

  tags = {
    Environment = "dev-staging"
    Project     = "CloudInsight"
    ManagedBy   = "Terraform"
  }
}
```

## Security Considerations

### Secret Access Patterns

The `allowed_secret_patterns` variable controls which secrets the role can access:

```hcl
# Example: Restrict to specific application secrets
allowed_secret_patterns = [
  "arn:aws:secretsmanager:*:*:secret:cloudinsight/user-service/*",
  "arn:aws:secretsmanager:*:*:secret:cloudinsight/order-service/*"
]

# Example: Allow all secrets (NOT recommended for production)
allowed_secret_patterns = ["*"]
```

### Recommendations

- **Production**: Use specific ARN patterns, not wildcards
- **Development**: Can use broader patterns for flexibility
- **Monitoring**: Enable CloudTrail for secret access auditing

## Requirements

- AWS Provider configured
- EKS cluster already exists
- Pod Identity addon enabled on the cluster

## Resources Created

- `aws_iam_role.secrets_access` - IAM role for Pod Identity
- `aws_iam_policy.secrets_access` - Policy for Secrets Manager access
- `aws_iam_role_policy_attachment.secrets_access` - Links policy to role

## Pod Identity vs IRSA

This module uses **EKS Pod Identity** instead of IRSA:

| Feature                     | IRSA     | Pod Identity    |
| --------------------------- | -------- | --------------- |
| Setup Complexity            | High     | Low             |
| OIDC Provider               | Required | Not needed      |
| Trust Policy                | Complex  | Simple          |
| Service Account Annotations | Required | Not needed      |
| AWS Support                 | Older    | Newer/Preferred |

## Next Steps

After creating the IAM role, you'll need:

1. Pod Identity associations (see `pod-identity-secrets` module)
2. SecretProviderClass resources in your application namespaces

## Example Secret ARN Patterns

```hcl
# Environment-specific secrets
"arn:aws:secretsmanager:us-west-2:123456789012:secret:dev/*"

# Application-specific secrets
"arn:aws:secretsmanager:*:*:secret:cloudinsight/user-service/*"

# All secrets in region (use with caution)
"arn:aws:secretsmanager:us-west-2:123456789012:secret:*"

# All secrets in account (NOT recommended)
"*"
```
