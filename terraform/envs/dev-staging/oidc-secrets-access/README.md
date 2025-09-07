# OIDC Secrets Access - Dev/Staging Environment

This configuration deploys the OIDC-based secrets access solution for the dev-staging environment.

## What it creates

- OIDC provider for the EKS cluster
- IAM role and policy for accessing AWS Secrets Manager
- Support for all microservices using IRSA (IAM Roles for Service Accounts)

## Deployment

1. Initialize Terraform:

```bash
terraform init -backend-config=backend.hcl
```

2. Plan the deployment:

```bash
terraform plan -var-file=terraform.tfvars
```

3. Apply the configuration:

```bash
terraform apply -var-file=terraform.tfvars
```

## Usage in Kubernetes

After deployment, you can annotate service accounts to use the OIDC role:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secrets-access-sa
  namespace: frontend-dev
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/cloudinsight-dev-staging-oidc-secrets-access
```

## SecretProviderClass Example

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: app-secrets
  namespace: frontend-dev
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "frontend-config"
        objectType: "secretsmanager"
        jmesPath:
          - path: "database_url"
            objectAlias: "db_url"
```
