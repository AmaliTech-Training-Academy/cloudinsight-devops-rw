#!/bin/bash

# Create AWS Secrets Manager secrets for CloudInsight project
# This script creates the secrets that the GitHub Actions workflows will use

set -e

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

# Configuration
BACKEND_SECRET_NAME="cloudinsight/backend/env"
FRONTEND_SECRET_NAME="cloudinsight/frontend/env"

echo "🔐 CloudInsight AWS Secrets Manager Setup"
echo "========================================"
echo

log_info "This script will create AWS Secrets Manager secrets for your GitHub Actions workflows."
log_info "The secrets will be created with empty JSON objects and populated by your CI/CD pipeline."
echo

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Get current AWS account info
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
AWS_REGION=$(aws configure get region 2>/dev/null || echo "")

if [[ -z "$AWS_ACCOUNT_ID" ]]; then
    log_error "Could not determine AWS account ID. Please configure AWS CLI."
    exit 1
fi

if [[ -z "$AWS_REGION" ]]; then
    log_warning "No default region configured. Using us-east-1."
    AWS_REGION="us-east-1"
fi

log_info "AWS Account: $AWS_ACCOUNT_ID"
log_info "AWS Region: $AWS_REGION"
echo

# Function to create secret
create_secret() {
    local secret_name="$1"
    local description="$2"
    
    log_info "Creating secret: $secret_name"
    
    if aws secretsmanager describe-secret --secret-id "$secret_name" >/dev/null 2>&1; then
        log_warning "Secret '$secret_name' already exists. Skipping creation."
        return 0
    fi
    
    if aws secretsmanager create-secret \
        --name "$secret_name" \
        --description "$description" \
        --secret-string "{}" >/dev/null 2>&1; then
        log_success "Created secret: $secret_name"
    else
        log_error "Failed to create secret: $secret_name"
        return 1
    fi
}

# Create secrets
echo "📝 Creating AWS Secrets Manager secrets..."
echo

create_secret "$BACKEND_SECRET_NAME" "Backend environment variables for CloudInsight project"
create_secret "$FRONTEND_SECRET_NAME" "Frontend environment variables for CloudInsight project"

echo
log_success "AWS Secrets Manager setup completed!"
echo

echo "📋 Next Steps:"
echo "============="
echo
echo "1. Configure the following GitHub repository secrets:"
echo "   Go to: Settings → Secrets and variables → Actions"
echo
echo "   Required secrets:"
echo "   • AWS_ROLE_ARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActions-CloudInsight-Role"
echo "   • AWS_REGION: ${AWS_REGION}"
echo "   • ECR_REGISTRY: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
echo "   • ECR_REPOSITORY_BACKEND: cloudinsight-backend"
echo "   • ECR_REPOSITORY_FRONTEND: cloudinsight-frontend"
echo "   • AWS_SECRET_NAME_BACKEND: ${BACKEND_SECRET_NAME}"
echo "   • AWS_SECRET_NAME_FRONTEND: ${FRONTEND_SECRET_NAME}"
echo
echo "2. If using encrypted environment variables, also add:"
echo "   • TEAM_PRIVATE_KEY: [Contents of your team-private-key.pem file]"
echo
echo "3. Your GitHub Actions workflows will now be able to:"
echo "   • Deploy environment variables to AWS Secrets Manager"
echo "   • Push Docker images to ECR"
echo "   • Create semantic version tags"
echo
echo "🚀 Ready to deploy!"