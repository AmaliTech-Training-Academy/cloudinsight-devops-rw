# GitHub Secrets Configuration Guide

## Required GitHub Repository Secrets

You need to configure the following secrets in your GitHub repository settings:

### Navigate to: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

## 1. AWS Configuration Secrets

| Secret Name    | Value                                                            | Description                            |
| -------------- | ---------------------------------------------------------------- | -------------------------------------- |
| `AWS_ROLE_ARN` | `arn:aws:iam::182399707265:role/GitHubActions-CloudInsight-Role` | IAM role for GitHub Actions            |
| `AWS_REGION`   | `eu-west-1`                                                      | AWS region (use your preferred region) |
| `ECR_REGISTRY` | `182399707265.dkr.ecr.eu-west-1.amazonaws.com`                   | ECR registry URL                       |

## 2. ECR Repository Names

| Secret Name               | Recommended Value       | Description                     |
| ------------------------- | ----------------------- | ------------------------------- |
| `ECR_REPOSITORY_BACKEND`  | `cloudinsight-backend`  | Backend Docker repository name  |
| `ECR_REPOSITORY_FRONTEND` | `cloudinsight-frontend` | Frontend Docker repository name |

## 3. AWS Secrets Manager Secret Names

| Secret Name                | Recommended Value           | Description                           |
| -------------------------- | --------------------------- | ------------------------------------- |
| `AWS_SECRET_NAME_BACKEND`  | `cloudinsight/backend/env`  | Backend environment variables secret  |
| `AWS_SECRET_NAME_FRONTEND` | `cloudinsight/frontend/env` | Frontend environment variables secret |

## 3. Encryption Key (if using encrypted environment variables)

| Secret Name        | Value                                | Description                                          |
| ------------------ | ------------------------------------ | ---------------------------------------------------- |
| `TEAM_PRIVATE_KEY` | `[Contents of team-private-key.pem]` | RSA private key for decrypting environment variables |

---

## Important Notes:

### Secret Naming Convention

The AWS Secrets Manager secret names **MUST** start with `cloudinsight/` or `cloudinsight-` to match the IAM policy resource pattern:

```
arn:aws:secretsmanager:*:182399707265:secret:cloudinsight/*
```

### Example Valid Secret Names:

- ✅ `cloudinsight/backend/env`
- ✅ `cloudinsight/frontend/env`
- ✅ `cloudinsight-backend-env`
- ✅ `cloudinsight/api/config`

### Example Invalid Secret Names:

- ❌ `backend-env` (doesn't start with cloudinsight)
- ❌ `myproject/backend` (wrong prefix)
- ❌ `env-vars` (wrong format)

---

## Quick Setup Commands

If you want to use the AWS CLI to create the secrets first (optional):

```bash
# Create backend secret (empty initially)
aws secretsmanager create-secret \
    --name "cloudinsight/backend/env" \
    --description "Backend environment variables for CloudInsight" \
    --secret-string "{}"

# Create frontend secret (empty initially)
aws secretsmanager create-secret \
    --name "cloudinsight/frontend/env" \
    --description "Frontend environment variables for CloudInsight" \
    --secret-string "{}"
```

The GitHub Actions workflows will populate these secrets when encrypted environment files are found and decrypted.
