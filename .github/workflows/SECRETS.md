# GitHub Secrets Configuration Guide

This document provides a comprehensive guide for configuring the required GitHub repository secrets to enable the reusable workflows functionality.

## 🔐 Required Secrets Overview

The reusable workflows require the following categories of secrets:

### 1. AWS Configuration Secrets
| Secret Name | Description | Required For | Example Value |
|-------------|-------------|--------------|---------------|
| `AWS_REGION` | AWS region for ECR and Secrets Manager | Build, Deploy | `us-east-1` |
| `AWS_ACCESS_KEY_ID` | AWS access key ID | Build, Deploy | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key | Build, Deploy | `wJalrXUt...` |
| `ECR_REPOSITORY_NAME` | ECR repository name for images | Build | `cloudinsight-app` |

### 2. Security Tool Secrets
| Secret Name | Description | Required For | Example Value |
|-------------|-------------|--------------|---------------|
| `SONARQUBE_URL` | SonarQube server URL | Security Scan | `https://sonarqube.company.com` |
| `SONARQUBE_TOKEN` | SonarQube authentication token | Security Scan | `squ_...` |
| `SONARQUBE_PROJECT_KEY` | SonarQube project key (optional) | Security Scan | `cloudinsight-backend` |
| `TRIVY_SERVER_URL` | Trivy server URL (optional) | Security Scan | `https://trivy.company.com` |
| `TRIVY_TOKEN` | Trivy authentication token (optional) | Security Scan | `trivy_...` |

### 3. Deployment Secrets
| Secret Name | Description | Required For | Example Value |
|-------------|-------------|--------------|---------------|
| `AWS_SECRETS_MANAGER_SECRET_NAME` | AWS Secrets Manager secret name | Deploy | `cloudinsight/production` |
| `DEPLOYMENT_SECRETS` | JSON object with secrets to deploy | Deploy | `{"DB_PASSWORD":"..."}` |
| `TEAM_PRIVATE_KEY` | RSA private key for env decryption | Build | `-----BEGIN RSA PRIVATE KEY-----...` |

## 🔧 Setting Up Secrets

### Step 1: Navigate to Repository Secrets

1. Go to your GitHub repository
2. Click on **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### Step 2: AWS Configuration

#### AWS Access Key and Secret
```bash
# Create IAM user with programmatic access
# Attach policies: AmazonEC2ContainerRegistryFullAccess, SecretsManagerReadWrite

AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIA1234567890EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

#### ECR Repository
```bash
# Create ECR repository first
aws ecr create-repository --repository-name cloudinsight-app --region us-east-1

ECR_REPOSITORY_NAME=cloudinsight-app
```

### Step 3: SonarQube Configuration

#### SonarQube Server Setup
```bash
# SonarQube server URL (without trailing slash)
SONARQUBE_URL=https://sonarqube.yourcompany.com

# Generate token in SonarQube: Account → Security → Generate Token
SONARQUBE_TOKEN=squ_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0

# Optional: Override default project key
SONARQUBE_PROJECT_KEY=cloudinsight-backend
```

#### SonarQube Project Setup
1. Create project in SonarQube
2. Set quality gate rules
3. Configure analysis parameters

### Step 4: Trivy Configuration (Optional)

```bash
# If using Trivy server mode
TRIVY_SERVER_URL=https://trivy.yourcompany.com
TRIVY_TOKEN=trivy_authentication_token
```

### Step 5: Deployment Secrets

#### AWS Secrets Manager Secret
```bash
# The name of the secret in AWS Secrets Manager
AWS_SECRETS_MANAGER_SECRET_NAME=cloudinsight/production

# JSON object containing secrets to deploy/update
DEPLOYMENT_SECRETS={
  "DATABASE_URL": "postgresql://user:pass@host:5432/db",
  "API_KEY": "your_api_key_here",
  "JWT_SECRET": "your_jwt_secret",
  "REDIS_URL": "redis://redis:6379"
}
```

#### Environment Decryption Key
```bash
# RSA private key for decrypting environment files
TEAM_PRIVATE_KEY=-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA7Jz...your_private_key_here...
-----END RSA PRIVATE KEY-----
```

## 🔒 Security Best Practices

### 1. IAM User Permissions

Create a dedicated IAM user with minimal required permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:UpdateSecret",
        "secretsmanager:CreateSecret",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:cloudinsight/*"
    }
  ]
}
```

### 2. Secret Rotation

- Rotate AWS access keys regularly (every 90 days)
- Rotate SonarQube tokens when team members change
- Update deployment secrets as needed

### 3. Environment-Specific Secrets

Consider using different secret values for different environments:

```bash
# Development
AWS_SECRETS_MANAGER_SECRET_NAME=cloudinsight/development

# Staging  
AWS_SECRETS_MANAGER_SECRET_NAME=cloudinsight/staging

# Production
AWS_SECRETS_MANAGER_SECRET_NAME=cloudinsight/production
```

## ✅ Validation Checklist

Use this checklist to ensure all secrets are properly configured:

### AWS Configuration
- [ ] `AWS_REGION` is set to correct region
- [ ] `AWS_ACCESS_KEY_ID` is valid IAM access key
- [ ] `AWS_SECRET_ACCESS_KEY` is valid IAM secret key
- [ ] `ECR_REPOSITORY_NAME` exists in specified region
- [ ] IAM user has ECR and Secrets Manager permissions

### SonarQube Configuration
- [ ] `SONARQUBE_URL` is accessible from GitHub Actions
- [ ] `SONARQUBE_TOKEN` has analysis permissions
- [ ] SonarQube project exists (or can be auto-created)
- [ ] Quality gate is configured with appropriate rules

### Trivy Configuration (if used)
- [ ] `TRIVY_SERVER_URL` is accessible (if using server mode)
- [ ] `TRIVY_TOKEN` is valid (if required by server)

### Deployment Configuration
- [ ] `AWS_SECRETS_MANAGER_SECRET_NAME` follows naming convention
- [ ] `DEPLOYMENT_SECRETS` is valid JSON format
- [ ] `TEAM_PRIVATE_KEY` matches encrypted environment files

## 🧪 Testing Secrets Configuration

### Test AWS Connection
```bash
# Test AWS credentials
aws sts get-caller-identity

# Test ECR access
aws ecr describe-repositories --repository-names cloudinsight-app
```

### Test SonarQube Connection
```bash
# Test SonarQube API access
curl -u "${SONARQUBE_TOKEN}:" "${SONARQUBE_URL}/api/system/status"
```

### Test Secrets Manager
```bash
# Test Secrets Manager access
aws secretsmanager describe-secret --secret-id cloudinsight/development
```

## 🚨 Troubleshooting

### Common Issues

#### 1. AWS ECR Login Failed
**Error**: `Unable to locate credentials`
**Solution**: Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are correct

#### 2. SonarQube Connection Failed
**Error**: `401 Unauthorized`
**Solution**: Check `SONARQUBE_TOKEN` and ensure it has analysis permissions

#### 3. Secrets Manager Access Denied
**Error**: `User is not authorized to perform: secretsmanager:GetSecretValue`
**Solution**: Add Secrets Manager permissions to IAM user

#### 4. Environment Decryption Failed
**Error**: `Decrypt failed`
**Solution**: Ensure `TEAM_PRIVATE_KEY` matches the public key used for encryption

### Debug Mode

Enable debug logging in workflows by setting:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

## 📚 Additional Resources

- [GitHub Actions Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [SonarQube Token Management](https://docs.sonarqube.org/latest/user-guide/user-token/)
- [AWS Secrets Manager Guide](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)

---

**Note**: Keep this configuration guide updated as requirements change and new secrets are added.