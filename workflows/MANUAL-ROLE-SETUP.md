# Manual AWS Role Creation Guide

If you prefer to create the AWS role manually instead of using the automated script, follow these steps:

## Prerequisites

1. AWS CLI installed and configured with administrative permissions
2. Access to your GitHub repository settings

## Step 1: Create OIDC Identity Provider

```bash
# Check if OIDC provider already exists
aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?ends_with(Arn, 'token.actions.githubusercontent.com')].Arn" --output text

# If it doesn't exist, create it
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
    --client-id-list sts.amazonaws.com
```

## Step 2: Create Trust Policy

Create a file called `trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:AmaliTech-Training-Academy/cloudinsight-devops-rw:*"
          ]
        }
      }
    }
  ]
}
```

**Replace `YOUR_ACCOUNT_ID` with your actual AWS account ID.**

## Step 3: Create Permissions Policy

Create a file called `permissions-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAuthentication",
      "Effect": "Allow",
      "Action": ["ecr:GetAuthorizationToken"],
      "Resource": "*"
    },
    {
      "Sid": "ECRRepositoryAccess",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage",
        "ecr:GetLifecyclePolicy",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:ListTagsForResource",
        "ecr:DescribeImageScanFindings",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": [
        "arn:aws:ecr:YOUR_REGION:YOUR_ACCOUNT_ID:repository/cloudinsight-*"
      ]
    },
    {
      "Sid": "SecretsManagerFullAccess",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:UpdateSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:PutSecretValue",
        "secretsmanager:TagResource",
        "secretsmanager:UntagResource",
        "secretsmanager:ListSecrets"
      ],
      "Resource": [
        "arn:aws:secretsmanager:YOUR_REGION:YOUR_ACCOUNT_ID:secret:cloudinsight/*"
      ]
    },
    {
      "Sid": "SecretsManagerListAll",
      "Effect": "Allow",
      "Action": ["secretsmanager:ListSecrets"],
      "Resource": "*"
    }
  ]
}
```

**Replace `YOUR_ACCOUNT_ID` and `YOUR_REGION` with your actual values.**

## Step 4: Create IAM Role

```bash
# Create the role
aws iam create-role \
    --role-name GitHubActions-CloudInsight-Role \
    --assume-role-policy-document file://trust-policy.json \
    --description "IAM role for GitHub Actions to access ECR and Secrets Manager for CloudInsight project"

# Create the policy
aws iam create-policy \
    --policy-name GitHubActions-CloudInsight-Policy \
    --policy-document file://permissions-policy.json \
    --description "Permissions for GitHub Actions to access ECR and Secrets Manager"

# Attach the policy to the role
aws iam attach-role-policy \
    --role-name GitHubActions-CloudInsight-Role \
    --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/GitHubActions-CloudInsight-Policy
```

## Step 5: Create ECR Repositories

```bash
# Create backend repository
aws ecr create-repository \
    --repository-name cloudinsight-backend \
    --region YOUR_REGION \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256

# Create frontend repository
aws ecr create-repository \
    --repository-name cloudinsight-frontend \
    --region YOUR_REGION \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256
```

## Step 6: Get Role ARN

```bash
aws iam get-role --role-name GitHubActions-CloudInsight-Role --query 'Role.Arn' --output text
```

## Step 7: Configure GitHub Secrets

Add these secrets to your GitHub repository at:
`https://github.com/AmaliTech-Training-Academy/cloudinsight-devops-rw/settings/secrets/actions`

| Secret Name                | Value                                                    |
| -------------------------- | -------------------------------------------------------- |
| `AWS_ROLE_ARN`             | The ARN from step 6                                      |
| `AWS_REGION`               | Your AWS region (e.g., `us-east-1`)                      |
| `ECR_REGISTRY`             | `YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com`      |
| `AWS_SECRET_NAME_BACKEND`  | `cloudinsight/backend/env`                               |
| `AWS_SECRET_NAME_FRONTEND` | `cloudinsight/frontend/env`                              |
| `TEAM_PRIVATE_KEY`         | Your RSA private key for environment variable decryption |

## Verification

Test the setup by running one of your GitHub Actions workflows. The workflow should be able to:

1. Authenticate with AWS using OIDC
2. Push Docker images to ECR
3. Create/update secrets in AWS Secrets Manager

## Troubleshooting

- If authentication fails, check the trust policy and OIDC provider configuration
- If ECR push fails, verify the ECR repository exists and the policy includes the correct permissions
- If Secrets Manager operations fail, check the policy includes the correct secret name patterns
