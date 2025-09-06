#!/bin/bash

# Validation script for enhanced CI/CD workflows
# This script validates the workflow files and required structure

set -e

echo "🔍 Validating Enhanced CI/CD Workflows"
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Validation functions
validate_workflow_structure() {
    print_status "Validating workflow directory structure..."
    
    if [ ! -d ".github/workflows" ]; then
        print_error ".github/workflows directory not found"
        return 1
    fi
    
    if [ ! -d ".github/workflows/backend" ]; then
        print_error ".github/workflows/backend directory not found"
        return 1
    fi
    
    if [ ! -d ".github/workflows/frontend" ]; then
        print_error ".github/workflows/frontend directory not found"
        return 1
    fi
    
    print_success "Workflow directory structure is valid"
}

validate_workflow_files() {
    print_status "Validating workflow files..."
    
    BACKEND_WORKFLOW=".github/workflows/backend/ci.yml"
    FRONTEND_WORKFLOW=".github/workflows/frontend/ci.yml"
    
    if [ ! -f "$BACKEND_WORKFLOW" ]; then
        print_error "Backend workflow file not found: $BACKEND_WORKFLOW"
        return 1
    fi
    
    if [ ! -f "$FRONTEND_WORKFLOW" ]; then
        print_error "Frontend workflow file not found: $FRONTEND_WORKFLOW"
        return 1
    fi
    
    # Validate YAML syntax
    if command -v python3 >/dev/null 2>&1; then
        print_status "Validating YAML syntax..."
        
        if ! python3 -c "import yaml; yaml.safe_load(open('$BACKEND_WORKFLOW'))" 2>/dev/null; then
            print_error "Backend workflow has invalid YAML syntax"
            return 1
        fi
        
        if ! python3 -c "import yaml; yaml.safe_load(open('$FRONTEND_WORKFLOW'))" 2>/dev/null; then
            print_error "Frontend workflow has invalid YAML syntax"
            return 1
        fi
        
        print_success "YAML syntax is valid for both workflows"
    else
        print_warning "Python3 not available - skipping YAML syntax validation"
    fi
    
    print_success "Workflow files are valid"
}

validate_encrypted_files() {
    print_status "Validating encrypted environment files..."
    
    REQUIRED_FILES=(
        "encrypted-aes-key.enc"
        "encrypted-env-vars.enc"
        "encrypted-env-vars.meta"
    )
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "Required encrypted file not found: $file"
            return 1
        fi
    done
    
    print_success "All required encrypted files are present"
}

validate_workflow_content() {
    print_status "Validating workflow content..."
    
    BACKEND_WORKFLOW=".github/workflows/backend/ci.yml"
    FRONTEND_WORKFLOW=".github/workflows/frontend/ci.yml"
    
    # Check for required jobs in backend workflow
    BACKEND_JOBS=("test" "deploy-secrets" "build-and-push")
    for job in "${BACKEND_JOBS[@]}"; do
        if ! grep -q "^  $job:" "$BACKEND_WORKFLOW"; then
            print_error "Backend workflow missing required job: $job"
            return 1
        fi
    done
    
    # Check for required jobs in frontend workflow
    FRONTEND_JOBS=("test" "deploy-secrets" "build-and-push")
    for job in "${FRONTEND_JOBS[@]}"; do
        if ! grep -q "^  $job:" "$FRONTEND_WORKFLOW"; then
            print_error "Frontend workflow missing required job: $job"
            return 1
        fi
    done
    
    # Check for semantic versioning step
    if ! grep -q "Generate semantic version tag" "$BACKEND_WORKFLOW"; then
        print_error "Backend workflow missing semantic versioning step"
        return 1
    fi
    
    if ! grep -q "Generate semantic version tag" "$FRONTEND_WORKFLOW"; then
        print_error "Frontend workflow missing semantic versioning step"
        return 1
    fi
    
    # Check for AWS Secrets Manager steps
    if ! grep -q "Deploy secrets to AWS Secrets Manager" "$BACKEND_WORKFLOW"; then
        print_error "Backend workflow missing AWS Secrets Manager deployment"
        return 1
    fi
    
    if ! grep -q "Deploy secrets to AWS Secrets Manager" "$FRONTEND_WORKFLOW"; then
        print_error "Frontend workflow missing AWS Secrets Manager deployment"
        return 1
    fi
    
    # Check for ECR steps
    if ! grep -q "Login to Amazon ECR" "$BACKEND_WORKFLOW"; then
        print_error "Backend workflow missing ECR login step"
        return 1
    fi
    
    if ! grep -q "Login to Amazon ECR" "$FRONTEND_WORKFLOW"; then
        print_error "Frontend workflow missing ECR login step"
        return 1
    fi
    
    print_success "Workflow content validation passed"
}

validate_documentation() {
    print_status "Validating documentation..."
    
    if [ ! -f ".github/workflows/README.md" ]; then
        print_warning "Workflow documentation not found (.github/workflows/README.md)"
    else
        print_success "Workflow documentation is present"
    fi
}

# Main validation
main() {
    echo
    print_status "Starting validation process..."
    echo
    
    validate_workflow_structure
    echo
    
    validate_workflow_files
    echo
    
    validate_encrypted_files
    echo
    
    validate_workflow_content
    echo
    
    validate_documentation
    echo
    
    print_success "🎉 All validations passed successfully!"
    echo
    print_status "Your enhanced CI/CD workflows are ready to use!"
    echo
    print_warning "Don't forget to configure the required GitHub secrets:"
    echo "  - AWS_REGION, AWS_ACCOUNT_ID, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
    echo "  - TEAM_PRIVATE_KEY"
    echo "  - AWS_SECRETS_MANAGER_SECRET_NAME_BACKEND, AWS_SECRETS_MANAGER_SECRET_NAME_FRONTEND"
    echo "  - ECR_REPOSITORY_BACKEND, ECR_REPOSITORY_FRONTEND"
}

# Check if we're in the right directory
if [ ! -f ".gitignore" ] || [ ! -d ".git" ]; then
    print_error "This script must be run from the repository root directory"
    exit 1
fi

# Run main validation
main