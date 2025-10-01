#!/bin/bash

# CI Workflow Deployment Script
# Automatically deploys CI workflows to predefined repositories across all branches

# set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
ORG="AmaliTech-Training-Academy"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_CI_FILE="$SCRIPT_DIR/frontend/ci.yml"
BACKEND_CI_FILE="$SCRIPT_DIR/backend/ci.yml"
BACKEND_NO_TESTS_CI_FILE="$SCRIPT_DIR/backend/ci-no-tests.yml"
TEMP_DIR="/tmp/ci-deployment-$$"
BRANCHES=("main")

# Infrastructure services that don't need tests
INFRASTRUCTURE_SERVICES=(
    "cloudinsight-api-gateway-rw"
    "cloudinsight-service-discovery-rw"
    "cloudinsight-config-server-rw"
)

# Default repository list with types
# Format: "repo-name:type" where type is either "frontend" or "backend"
REPOS=(
    # Frontend repositories
    # "cloudinsight-frontend-rw:frontend"
    
    # Backend repositories
    "cloudinsight-api-gateway-rw:backend"
    "cloudinsight-service-discovery-rw:backend"
    # "cloudinsight-config-server-rw:backend"
    # "cloudinsight-user-service-rw:backend"
    # "cloudinsight-cost-service-rw:backend"
    # "cloudinsight-metric-service-rw:backend"
    # "cloudinsight-anomaly-service-rw:backend"
    # "cloudinsight-forecast-service-rw:backend"
    # "cloudinsight-notification-service-rw:backend"
    
    # Add more repositories as needed
    # "your-repo-name:frontend"
    # "your-repo-name:backend"
)

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo ""
    echo -e "${BLUE}$1${NC}"
    echo "==============================="
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if gh CLI is installed and authenticated
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        exit 1
    fi
    
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated. Please run 'gh auth login'"
        exit 1
    fi
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed"
        exit 1
    fi
    
    # Check if CI files exist
    if [[ ! -f "$FRONTEND_CI_FILE" ]]; then
        log_error "Frontend CI file not found at: $FRONTEND_CI_FILE"
        exit 1
    fi
    
    if [[ ! -f "$BACKEND_CI_FILE" ]]; then
        log_error "Backend CI file not found at: $BACKEND_CI_FILE"
        exit 1
    fi
    
    if [[ ! -f "$BACKEND_NO_TESTS_CI_FILE" ]]; then
        log_error "Backend no-tests CI file not found at: $BACKEND_NO_TESTS_CI_FILE"
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

# Parse repository and type from input
parse_repo_input() {
    local input="$1"
    
    if [[ "$input" == *":frontend" ]]; then
        REPO_NAME="${input%:frontend}"
        REPO_TYPE="frontend"
    elif [[ "$input" == *":backend" ]]; then
        REPO_NAME="${input%:backend}"
        REPO_TYPE="backend"
    else
        log_error "Invalid repository format: $input"
        log_error "Expected format: repo-name:frontend or repo-name:backend"
        return 1
    fi
    
    return 0
}

# Check if repository is an infrastructure service
is_infrastructure_service() {
    local repo_name="$1"
    
    for infra_service in "${INFRASTRUCTURE_SERVICES[@]}"; do
        if [[ "$repo_name" == "$infra_service" ]]; then
            return 0
        fi
    done
    return 1
}

# Get the appropriate CI file based on repository type
get_ci_file() {
    local repo_type="$1"
    local repo_name="$2"
    
    if [[ "$repo_type" == "frontend" ]]; then
        echo "$FRONTEND_CI_FILE"
    elif [[ "$repo_type" == "backend" ]]; then
        # Check if this is an infrastructure service
        if is_infrastructure_service "$repo_name"; then
            echo "$BACKEND_NO_TESTS_CI_FILE"
        else
            echo "$BACKEND_CI_FILE"
        fi
    else
        log_error "Unknown repository type: $repo_type"
        return 1
    fi
}

# Check if repository exists
check_repository_exists() {
    local repo="$1"
    
    if gh repo view "$ORG/$repo" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get repository default branch
get_default_branch() {
    local repo="$1"
    
    gh repo view "$ORG/$repo" --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || echo "main"
}

# Check if branch exists in repository
check_branch_exists() {
    local repo="$1"
    local branch="$2"
    
    gh api "repos/$ORG/$repo/branches/$branch" &> /dev/null
}

# Create branch if it doesn't exist
create_branch_if_needed() {
    local repo="$1"
    local branch="$2"
    local default_branch="$3"
    
    if ! check_branch_exists "$repo" "$branch"; then
        log_info "  → Creating branch $branch from $default_branch..."
        
        # Get the SHA of the default branch
        local sha=$(gh api "repos/$ORG/$repo/git/ref/heads/$default_branch" --jq '.object.sha')
        
        # Create the new branch
        gh api --method POST "repos/$ORG/$repo/git/refs" \
            --field ref="refs/heads/$branch" \
            --field sha="$sha" &> /dev/null
        
        log_success "  ✓ Created branch $branch"
    else
        log_info "  ✓ Branch $branch already exists"
    fi
}

# Deploy CI workflow to a specific branch
deploy_to_branch() {
    local repo="$1"
    local repo_type="$2"
    local branch="$3"
    local ci_file="$4"
    
    log_info "  → Deploying $repo_type CI to branch: $branch"
    
    # Create temporary directory for this operation
    local branch_temp_dir="$TEMP_DIR/$repo-$branch"
    mkdir -p "$branch_temp_dir"
    
    cd "$branch_temp_dir"
    
    # Clone the specific branch
    if ! git clone -b "$branch" "https://github.com/$ORG/$repo.git" . &> /dev/null; then
        log_error "Failed to clone branch $branch from $repo"
        return 1
    fi
    
    # Configure git
    git config user.email "clmntmugisha@gmail.com"
    git config user.name "bikaze"
    
    # Create .github/workflows directory if it doesn't exist
    mkdir -p .github/workflows
    
    # Copy the appropriate CI file
    cp "$ci_file" .github/workflows/ci.yml
    
    # Check if there are changes to commit
    if git diff --quiet && git diff --staged --quiet; then
        log_info "  ✓ CI workflow already up to date on $branch"
        cd - &> /dev/null
        return 0
    fi
    
    # Add and commit changes
    git add .github/workflows/ci.yml
    git commit -m "Update CI workflow for $repo_type project

- Deploy $repo_type-specific CI pipeline
- Automated deployment via deploy-ci-workflows.sh
- Branch: $branch
- Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" &> /dev/null
    
    # Push changes directly (admin privileges allow bypassing branch protection)
    if git push origin "$branch" &> /dev/null; then
        log_success "  ✓ Successfully deployed CI workflow to $branch"
    else
        log_error "Failed to push CI workflow to $branch"
        cd - &> /dev/null
        return 1
    fi
    
    cd - &> /dev/null
    return 0
}

# Deploy CI workflow to a repository
deploy_to_repository() {
    local repo_input="$1"
    local repo_name repo_type ci_file default_branch
    
    # Parse repository input
    if ! parse_repo_input "$repo_input"; then
        return 1
    fi
    
    repo_name="$REPO_NAME"
    repo_type="$REPO_TYPE"
    
    log_header "🚀 Processing Repository: $repo_name ($repo_type)"
    
    # Check if repository exists
    if ! check_repository_exists "$repo_name"; then
        log_error "Repository $ORG/$repo_name does not exist or is not accessible"
        return 1
    fi
    
    log_success "Repository $repo_name found"
    
    # Get CI file for this repository type
    if ! ci_file=$(get_ci_file "$repo_type" "$repo_name"); then
        return 1
    fi
    
    # Determine CI file type for logging
    if [[ "$ci_file" == *"ci-no-tests.yml" ]]; then
        log_info "Using CI file: $(basename "$ci_file") (infrastructure service - no tests)"
    else
        log_info "Using CI file: $(basename "$ci_file")"
    fi
    
    # Get default branch
    default_branch=$(get_default_branch "$repo_name")
    log_info "Default branch: $default_branch"
    
    # Process each target branch
    local success_count=0
    local total_branches=${#BRANCHES[@]}
    
    for branch in "${BRANCHES[@]}"; do
        log_info "Processing branch: $branch"
        
        # Create branch if it doesn't exist
        create_branch_if_needed "$repo_name" "$branch" "$default_branch"
        
        # Deploy CI workflow to this branch (admin privileges bypass branch protection)
        if deploy_to_branch "$repo_name" "$repo_type" "$branch" "$ci_file"; then
            ((success_count++))
        fi
        
        # Small delay between branches
        sleep 1
    done
    
    if [[ $success_count -eq $total_branches ]]; then
        log_success "✅ Successfully deployed CI workflow to all branches in $repo_name"
        return 0
    else
        log_warning "⚠️  Deployed CI workflow to $success_count/$total_branches branches in $repo_name"
        return 1
    fi
}

# Main function
main() {
    log_header "🔄 CI Workflow Deployment Script"
    
    check_prerequisites
    
    # Use predefined REPOS array
    log_info "Processing ${#REPOS[@]} predefined repositories:"
    
    # Display the repositories that will be processed
    for repo in "${REPOS[@]}"; do
        echo "  - $repo"
    done
    echo ""
    
    # Ask for confirmation
    read -p "Do you want to proceed with deploying CI workflows to these repositories? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deployment cancelled by user"
        exit 0
    fi
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Process each repository
    local total_repos=${#REPOS[@]}
    local successful_repos=0
    
    log_info "Deploying CI workflows to $total_repos repositories..."
    log_info "Target branches: ${BRANCHES[*]}"
    echo ""
    
    for repo_input in "${REPOS[@]}"; do
        if deploy_to_repository "$repo_input"; then
            ((successful_repos++))
        fi
        echo ""
    done
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    # Summary
    log_header "📊 Deployment Summary"
    if [[ $successful_repos -eq $total_repos ]]; then
        log_success "Successfully deployed CI workflows to all $total_repos repositories"
        log_info "Branches updated: ${BRANCHES[*]}"
        log_info "All repositories are now configured with appropriate CI workflows"
    else
        log_warning "Deployed CI workflows to $successful_repos out of $total_repos repositories"
        log_info "Check the logs above for any failed deployments"
    fi
    
    echo ""
    log_info "🎉 CI Workflow deployment completed!"
    echo ""
    echo "Next steps:"
    echo "  1. Verify the workflows in the GitHub repositories"
    echo "  2. Test the CI pipelines by making commits to the branches"
    echo "  3. Check GitHub Actions tabs for workflow execution"
}

# Run main function
main
