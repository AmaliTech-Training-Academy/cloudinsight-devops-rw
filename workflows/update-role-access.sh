#!/bin/bash

# Update existing IAM role to allow access from any AmaliTech repository
# This script updates the trust policy to allow repo:AmaliTech-Training-Academy/*:*

set -e

# Configuration
ROLE_NAME="GitHubActions-CloudInsight-Role"
GITHUB_REPO_OWNER="AmaliTech-Training-Academy"

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is configured
check_aws_cli() {
    log_info "Checking AWS CLI configuration..."
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Get AWS account ID
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
    
    if [[ -z "$AWS_ACCOUNT_ID" ]]; then
        log_error "AWS CLI is not configured or you don't have proper credentials."
        exit 1
    fi
    
    log_success "AWS CLI configured. Account ID: $AWS_ACCOUNT_ID"
}

# Get OIDC provider ARN
get_oidc_provider() {
    log_info "Getting OIDC provider ARN..."
    
    OIDC_PROVIDER_ARN=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?ends_with(Arn, 'token.actions.githubusercontent.com')].Arn" --output text 2>/dev/null || echo "")
    
    if [[ -z "$OIDC_PROVIDER_ARN" ]]; then
        log_error "GitHub Actions OIDC provider not found. Please run the create-github-actions-role.sh script first."
        exit 1
    fi
    
    log_success "OIDC provider found: $OIDC_PROVIDER_ARN"
}

# Create new trust policy
create_new_trust_policy() {
    log_info "Creating updated trust policy for all AmaliTech repositories..."
    
    cat > /tmp/new-trust-policy.json << EOF
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
    
    log_success "New trust policy created (allows all AmaliTech repositories)"
}

# Update the IAM role trust policy
update_role_trust_policy() {
    log_info "Updating IAM role trust policy..."
    
    # Check if role exists
    if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
        log_error "Role $ROLE_NAME does not exist. Please run the create-github-actions-role.sh script first."
        exit 1
    fi
    
    # Update the trust policy
    aws iam update-assume-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-document file:///tmp/new-trust-policy.json
    
    log_success "Role trust policy updated successfully"
}

# Cleanup temporary files
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f /tmp/new-trust-policy.json
    log_success "Cleanup completed"
}

# Display the updated configuration
display_updated_access() {
    log_info "Updated Role Access Configuration:"
    echo
    echo -e "${YELLOW}Role Name:${NC} $ROLE_NAME"
    echo -e "${YELLOW}Access Scope:${NC} All repositories under ${GITHUB_REPO_OWNER}"
    echo
    echo -e "${GREEN}Repositories that can now use this role:${NC}"
    echo "  ✅ ${GITHUB_REPO_OWNER}/cloudinsight-devops-rw"
    echo "  ✅ ${GITHUB_REPO_OWNER}/cloudinsight-backend"
    echo "  ✅ ${GITHUB_REPO_OWNER}/cloudinsight-frontend"
    echo "  ✅ ${GITHUB_REPO_OWNER}/* (any repository in the organization)"
    echo
    echo -e "${BLUE}Each repository will need the same GitHub secrets:${NC}"
    echo "  - AWS_ROLE_ARN = arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME"
    echo "  - AWS_REGION = (your region)"
    echo "  - ECR_REGISTRY = (your ECR registry URL)"
    echo "  - AWS_SECRET_NAME_BACKEND/FRONTEND = (your secret names)"
    echo "  - TEAM_PRIVATE_KEY = (your RSA private key)"
}

# Main execution
main() {
    echo -e "${BLUE}Update CloudInsight GitHub Actions Role Access${NC}"
    echo "=============================================="
    echo
    
    # Check prerequisites
    check_aws_cli
    
    # Get OIDC provider
    get_oidc_provider
    
    # Create and apply new trust policy
    create_new_trust_policy
    update_role_trust_policy
    
    # Cleanup
    cleanup
    
    # Display results
    echo
    echo -e "${GREEN}===============================================${NC}"
    echo -e "${GREEN}Role Access Updated Successfully!${NC}"
    echo -e "${GREEN}===============================================${NC}"
    echo
    
    display_updated_access
    
    echo
    log_success "All AmaliTech repositories can now use this AWS role!"
}

# Run the script
main "$@"