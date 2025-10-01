#!/bin/bash

# CloudInsight GitHub Actions AWS Role Creation Script
# This script creates an IAM role for GitHub Actions with permissions for ECR and Secrets Manager
# Uses your default AWS CLI configuration (account ID and region)

set -e

# Configuration
ROLE_NAME="GitHubActions-CloudInsight-Role"
POLICY_NAME="GitHubActions-CloudInsight-Policy"
GITHUB_REPO_OWNER="AmaliTech-Training-Academy"
GITHUB_REPO_NAME="cloudinsight-devops-rw"
AWS_ACCOUNT_ID=""
AWS_REGION=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed and configured
check_aws_cli() {
    log_info "Checking AWS CLI configuration..."
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Get AWS account ID and region from current AWS configuration
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
    AWS_REGION=$(aws configure get region 2>/dev/null || echo "")
    
    if [[ -z "$AWS_ACCOUNT_ID" ]]; then
        log_error "AWS CLI is not configured or you don't have proper credentials."
        log_error "Please run 'aws configure' or set up your AWS credentials."
        exit 1
    fi
    
    if [[ -z "$AWS_REGION" ]]; then
        log_error "No default region configured in AWS CLI."
        log_error "Please run 'aws configure set region <your-region>' to set a default region."
        exit 1
    fi
    
    log_success "AWS CLI configured. Account ID: $AWS_ACCOUNT_ID, Region: $AWS_REGION"
}

# Create OIDC identity provider for GitHub Actions
create_oidc_provider() {
    log_info "Creating OIDC identity provider for GitHub Actions..."
    
    # Check if OIDC provider already exists
    EXISTING_PROVIDER=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?ends_with(Arn, 'token.actions.githubusercontent.com')].Arn" --output text 2>/dev/null || echo "")
    
    if [[ -n "$EXISTING_PROVIDER" ]]; then
        log_success "OIDC provider already exists: $EXISTING_PROVIDER"
        OIDC_PROVIDER_ARN="$EXISTING_PROVIDER"
    else
        log_info "Creating new OIDC provider..."
        
        # Create the OIDC provider
        OIDC_PROVIDER_ARN=$(aws iam create-open-id-connect-provider \
            --url https://token.actions.githubusercontent.com \
            --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
            --client-id-list sts.amazonaws.com \
            --query 'OpenIDConnectProviderArn' \
            --output text)
        
        log_success "OIDC provider created: $OIDC_PROVIDER_ARN"
    fi
}

# Create trust policy for the role
create_trust_policy() {
    log_info "Creating trust policy for GitHub Actions..."
    
    cat > /tmp/trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "$OIDC_PROVIDER_ARN"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": [
                        "repo:${GITHUB_REPO_OWNER}/*:*"
                    ]
                }
            }
        }
    ]
}
EOF
    
    log_success "Trust policy created"
}

# Create permissions policy for ECR and Secrets Manager
create_permissions_policy() {
    log_info "Creating permissions policy for ECR and Secrets Manager..."
    
    cat > /tmp/permissions-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ECRAuthentication",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
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
                "arn:aws:ecr:*:${AWS_ACCOUNT_ID}:repository/cloudinsight-*"
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
                "arn:aws:secretsmanager:*:${AWS_ACCOUNT_ID}:secret:cloudinsight/*"
            ]
        },
        {
            "Sid": "SecretsManagerListAll",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:ListSecrets"
            ],
            "Resource": "*"
        }
    ]
}
EOF
    
    log_success "Permissions policy created"
}

# Create the IAM role
create_iam_role() {
    log_info "Creating IAM role: $ROLE_NAME..."
    
    # Check if role already exists
    if aws iam get-role --role-name "$ROLE_NAME" &>/dev/null; then
        log_warning "Role $ROLE_NAME already exists. Updating trust policy..."
        aws iam update-assume-role-policy --role-name "$ROLE_NAME" --policy-document file:///tmp/trust-policy.json
    else
        aws iam create-role \
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document file:///tmp/trust-policy.json \
            --description "IAM role for GitHub Actions to access ECR and Secrets Manager for CloudInsight project"
        
        log_success "IAM role $ROLE_NAME created"
    fi
    
    # Get role ARN
    ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
    log_success "Role ARN: $ROLE_ARN"
}

# Create and attach the permissions policy
create_and_attach_policy() {
    log_info "Creating and attaching permissions policy: $POLICY_NAME..."
    
    # Check if policy already exists
    POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}"
    
    if aws iam get-policy --policy-arn "$POLICY_ARN" &>/dev/null; then
        log_warning "Policy $POLICY_NAME already exists. Creating new version..."
        aws iam create-policy-version \
            --policy-arn "$POLICY_ARN" \
            --policy-document file:///tmp/permissions-policy.json \
            --set-as-default
    else
        aws iam create-policy \
            --policy-name "$POLICY_NAME" \
            --policy-document file:///tmp/permissions-policy.json \
            --description "Permissions for GitHub Actions to access ECR and Secrets Manager"
        
        log_success "Policy $POLICY_NAME created"
    fi
    
    # Attach policy to role
    aws iam attach-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-arn "$POLICY_ARN"
    
    log_success "Policy attached to role"
}

# Create ECR repositories if they don't exist
create_ecr_repositories() {
    log_info "Creating ECR repositories..."
    
    REPOSITORIES=("cloudinsight-backend" "cloudinsight-frontend")
    
    for repo in "${REPOSITORIES[@]}"; do
        if aws ecr describe-repositories --repository-names "$repo" &>/dev/null; then
            log_success "ECR repository $repo already exists"
        else
            log_info "Creating ECR repository: $repo"
            aws ecr create-repository \
                --repository-name "$repo" \
                --image-scanning-configuration scanOnPush=true \
                --encryption-configuration encryptionType=AES256
            
            log_success "ECR repository $repo created"
        fi
    done
    
    # Get ECR registry URL
    ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    log_success "ECR Registry URL: $ECR_REGISTRY"
}

# Cleanup temporary files
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f /tmp/trust-policy.json /tmp/permissions-policy.json
    log_success "Cleanup completed"
}

# Display GitHub secrets that need to be configured
display_github_secrets() {
    log_info "GitHub Secrets Configuration Required:"
    echo
    echo -e "${YELLOW}Add the following secrets to your GitHub repository:${NC}"
    echo -e "${YELLOW}Repository: ${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}${NC}"
    echo
    echo -e "${GREEN}AWS_ROLE_ARN${NC} = $ROLE_ARN"
    echo -e "${GREEN}AWS_REGION${NC} = $AWS_REGION"
    echo -e "${GREEN}ECR_REGISTRY${NC} = $ECR_REGISTRY"
    echo -e "${GREEN}AWS_SECRET_NAME_BACKEND${NC} = cloudinsight/backend/env"
    echo -e "${GREEN}AWS_SECRET_NAME_FRONTEND${NC} = cloudinsight/frontend/env"
    echo
    echo -e "${BLUE}To add these secrets:${NC}"
    echo "1. Go to https://github.com/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/settings/secrets/actions"
    echo "2. Click 'New repository secret'"
    echo "3. Add each secret with the values shown above"
    echo
    echo -e "${YELLOW}Note: You also need to add your TEAM_PRIVATE_KEY secret for environment variable decryption${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}CloudInsight GitHub Actions AWS Role Setup${NC}"
    echo "==========================================="
    echo
    
    # Check prerequisites
    check_aws_cli
    
    # Create OIDC provider
    create_oidc_provider
    
    # Create policies and role
    create_trust_policy
    create_permissions_policy
    create_iam_role
    create_and_attach_policy
    
    # Create ECR repositories
    create_ecr_repositories
    
    # Cleanup
    cleanup
    
    # Display configuration instructions
    echo
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}AWS Role Setup Completed Successfully!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo
    
    display_github_secrets
    
    echo
    log_success "Setup completed! Your GitHub Actions workflows can now authenticate with AWS."
}

# Run the script
main "$@"