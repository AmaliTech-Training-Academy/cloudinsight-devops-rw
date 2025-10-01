# CloudInsight CI/CD Workflows

This directory contains GitHub Actions workflows for the CloudInsight project's frontend and backend applications.

## 🚀 Features

Both workflows have been upgraded to include:

- **✅ Environment Variable Deployment**: Automatically deploys decrypted environment variables to AWS Secrets Manager
- **✅ Merge Strategy**: Updates existing secrets without removing other values using merge strategy
- **✅ ECR Image Push**: Builds and pushes Docker images to Amazon ECR
- **✅ Semantic Versioning**: Automatically increments patch version based on latest git tags
- **✅ Multi-Platform Support**: Builds for both `linux/amd64` and `linux/arm64` architectures

## 📋 Workflows

### Backend Workflow (`backend/ci.yml`)

- Java/Spring Boot application CI/CD
- Maven-based build and test
- JaCoCo code coverage
- Docker multi-platform build and push to ECR
- Environment variables deployment to AWS Secrets Manager

### Frontend Workflow (`frontend/ci.yml`)

- Next.js application CI/CD
- pnpm dependency management
- Vitest testing with coverage
- Docker multi-platform build and push to ECR
- NEXT*PUBLIC*\* environment variables handling
- Environment variables deployment to AWS Secrets Manager

## 🔐 Required GitHub Secrets

Both workflows require the following secrets to be configured in your GitHub repository:

### AWS Configuration

| Secret Name    | Description                              | Example                                             |
| -------------- | ---------------------------------------- | --------------------------------------------------- |
| `AWS_ROLE_ARN` | AWS IAM role ARN for OIDC authentication | `arn:aws:iam::123456789012:role/GitHubActions-Role` |
| `AWS_REGION`   | AWS region for deployment                | `us-east-1`                                         |
| `ECR_REGISTRY` | ECR registry URL                         | `123456789012.dkr.ecr.us-east-1.amazonaws.com`      |

### Secrets Manager

| Secret Name                | Description                                  | Example                     |
| -------------------------- | -------------------------------------------- | --------------------------- |
| `AWS_SECRET_NAME_BACKEND`  | AWS Secrets Manager secret name for backend  | `cloudinsight/backend/env`  |
| `AWS_SECRET_NAME_FRONTEND` | AWS Secrets Manager secret name for frontend | `cloudinsight/frontend/env` |

### Encryption

| Secret Name        | Description                                          |
| ------------------ | ---------------------------------------------------- |
| `TEAM_PRIVATE_KEY` | RSA private key for decrypting environment variables |

## 🏷️ Semantic Versioning

The workflows automatically handle semantic versioning:

1. **Detection**: Finds the latest tag matching `v*.*.*` pattern on the current branch
2. **Increment**: Automatically increments the patch version by +1
3. **Tagging**: Creates and pushes new tags only on `main` branch pushes
4. **Docker Tags**: Tags Docker images with:
   - `latest`
   - Semantic version (e.g., `1.2.3`)
   - Git commit SHA

### Examples

- Latest tag: `v1.2.3` → Next version: `v1.2.4`
- Latest tag: `v0.1.0` → Next version: `v0.1.1`
- No tags found → Next version: `v0.0.1`

## 🔄 AWS Secrets Manager Merge Strategy

The workflows implement a smart merge strategy for AWS Secrets Manager:

1. **Existing Secrets**: If secret exists, fetch current values
2. **Merge Logic**: Update only the keys present in the `.env` file
3. **Preservation**: Keep existing keys not present in `.env` unchanged
4. **New Secrets**: Create new secret if it doesn't exist

This ensures that:

- Manual or other automated updates to secrets are preserved
- Only intended environment variables are updated
- No accidental deletion of existing configurations

## 🛠️ Setup Instructions

1. **Configure AWS OIDC**: Set up OpenID Connect between GitHub and AWS
2. **Create ECR Repositories**:
   - `cloudinsight-backend`
   - `cloudinsight-frontend`
3. **Configure GitHub Secrets**: Add all required secrets listed above
4. **Prepare Environment Files**: Encrypt your environment variables using the team encryption scripts
5. **Push Code**: The workflows will automatically trigger on push/PR events

## 🔍 Workflow Triggers

- **Push**: Any branch push triggers the workflow
- **Pull Request**: Any PR to any branch triggers the workflow
- **Merge Group**: Merge queue events trigger the workflow
- **Tagging**: Only happens on `main` branch pushes
- **ECR Push**: Only happens when workflows complete successfully

## 📊 Test and Coverage Reports

Both workflows generate:

- Test result annotations in PR/commit views
- Coverage reports uploaded as artifacts
- Test summaries in GitHub Step Summary
- JUnit XML and coverage data for further analysis

## 🔒 Security Features

- Environment variables are masked in logs
- Private keys are cleaned up after use
- Temporary files are securely deleted
- AWS credentials use OIDC (no long-term secrets)
- Principle of least privilege for GitHub token permissions

## 🚨 Troubleshooting

### Common Issues

1. **AWS Authentication Failures**

   - Verify `AWS_ROLE_ARN` and `AWS_REGION` secrets
   - Check OIDC trust relationship in AWS IAM

2. **ECR Push Failures**

   - Ensure ECR repositories exist
   - Verify `ECR_REGISTRY` secret format

3. **Secrets Manager Errors**

   - Check `AWS_SECRET_NAME_*` secret names
   - Verify IAM permissions for Secrets Manager

4. **Decryption Failures**

   - Verify `TEAM_PRIVATE_KEY` secret content
   - Check if encrypted files exist in repository

5. **Tag Creation Failures**
   - Ensure workflows have `contents: write` permission
   - Check for existing tags with same version

For detailed logs, check the GitHub Actions run details in your repository.
