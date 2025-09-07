# OIDC Secrets Access Module

This module creates an OIDC provider and IAM role for accessing AWS Secrets Manager using IRSA (IAM Roles for Service Accounts) with Kubernetes service accounts.

## Features

- Creates OIDC provider for the EKS cluster
- Creates IAM role and policy for secrets access
- Supports multiple services and namespaces
- Uses IRSA for secure authentication

## Usage

```hcl
module "oidc_secrets_access" {
  source = "../../../modules/oidc-secrets-access"

  cluster_name = data.terraform_remote_state.eks.outputs.cluster_name

  services = [
    {
      name            = "frontend"
      namespace       = "frontend-dev"
      service_account = "secrets-access-sa"
    },
    {
      name            = "backend"
      namespace       = "backend-dev"
      service_account = "secrets-access-sa"
    }
  ]

  secrets_arns = [
    "arn:aws:secretsmanager:region:account:secret:frontend/*",
    "arn:aws:secretsmanager:region:account:secret:backend/*"
  ]

  tags = {
    Environment = "dev"
    Project     = "cloudinsight"
  }
}
```

## Inputs

| Name         | Description                                  | Type           | Default | Required |
| ------------ | -------------------------------------------- | -------------- | ------- | :------: |
| cluster_name | Name of the EKS cluster                      | `string`       | n/a     |   yes    |
| services     | List of services that need secrets access    | `list(object)` | `[]`    |    no    |
| secrets_arns | List of secret ARNs that services can access | `list(string)` | `["*"]` |    no    |
| tags         | Tags to apply to resources                   | `map(string)`  | `{}`    |    no    |

## Outputs

| Name               | Description                              |
| ------------------ | ---------------------------------------- |
| oidc_provider_arn  | ARN of the OIDC provider                 |
| oidc_provider_url  | URL of the OIDC provider                 |
| secrets_role_arn   | ARN of the IAM role for secrets access   |
| secrets_role_name  | Name of the IAM role for secrets access  |
| secrets_policy_arn | ARN of the IAM policy for secrets access |

## Requirements

- EKS cluster must already exist
- Secrets Store CSI Driver must be installed
