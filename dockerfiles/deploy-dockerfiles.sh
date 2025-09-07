#!/bin/bash

# Dockerfile Deployment Script
# Automatically deploys Dockerfiles to predefined repositories across all branches

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
ORG="AmaliTech-Training-Academy"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DOCKERFILE="$SCRIPT_DIR/frontend/Dockerfile"
BACKEND_DOCKERFILE="$SCRIPT_DIR/backend/Dockerfile"
FRONTEND_DOCKERIGNORE="$SCRIPT_DIR/frontend/.dockerignore"
BACKEND_DOCKERIGNORE="$SCRIPT_DIR/backend/.dockerignore"
TEMP_DIR="/tmp/dockerfile-deployment-$$"
BRANCHES=("main" "development" "staging" "production")

# Default repository list with types
# Format: "repo-name:type" where type is either "frontend" or "backend"
REPOS=(
    # Frontend repositories
    # "cloudinsight-frontend-rw:frontend"
    
    # Backend repositories  
    "cloudinsight-api-gateway-rw:backend"
    "cloudinsight-service-discovery-rw:backend"
    "cloudinsight-config-server-rw:backend"
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
    echo -e "\n${BLUE}=====================================${NC}"
    echo -e "${BLUE}🐳 $1${NC}"
    echo -e "${BLUE}=====================================${NC}\n"
}

# Cleanup function
cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log_info "Cleaned up temporary directory: $TEMP_DIR"
    fi
}

# Set trap to cleanup on script exit
trap cleanup EXIT

# Validation functions
validate_dependencies() {
    local missing_deps=()
    
    if ! command -v gh &> /dev/null; then
        missing_deps+=("gh (GitHub CLI)")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            log_error "  - $dep"
        done
        log_info "Please install missing dependencies and try again."
        exit 1
    fi
    
    # Check GitHub CLI authentication
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated."
        log_info "Please run 'gh auth login' first."
        exit 1
    fi
    
    log_success "All dependencies validated"
}

validate_dockerfile_files() {
    local missing_files=()
    
    if [[ ! -f "$FRONTEND_DOCKERFILE" ]]; then
        missing_files+=("Frontend Dockerfile: $FRONTEND_DOCKERFILE")
    fi
    
    if [[ ! -f "$BACKEND_DOCKERFILE" ]]; then
        missing_files+=("Backend Dockerfile: $BACKEND_DOCKERFILE")
    fi
    
    if [[ ! -f "$FRONTEND_DOCKERIGNORE" ]]; then
        missing_files+=("Frontend .dockerignore: $FRONTEND_DOCKERIGNORE")
    fi
    
    if [[ ! -f "$BACKEND_DOCKERIGNORE" ]]; then
        missing_files+=("Backend .dockerignore: $BACKEND_DOCKERIGNORE")
    fi
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "Missing Docker files:"
        for file in "${missing_files[@]}"; do
            log_error "  - $file"
        done
        exit 1
    fi
    
    log_success "All Docker files found (Dockerfile + .dockerignore)"
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

# Get the appropriate Dockerfile based on repository type
get_dockerfile() {
    local repo_type="$1"
    
    if [[ "$repo_type" == "frontend" ]]; then
        echo "$FRONTEND_DOCKERFILE"
    elif [[ "$repo_type" == "backend" ]]; then
        echo "$BACKEND_DOCKERFILE"
    else
        log_error "Unknown repository type: $repo_type"
        return 1
    fi
}

# Get the appropriate .dockerignore based on repository type
get_dockerignore() {
    local repo_type="$1"
    
    if [[ "$repo_type" == "frontend" ]]; then
        echo "$FRONTEND_DOCKERIGNORE"
    elif [[ "$repo_type" == "backend" ]]; then
        echo "$BACKEND_DOCKERIGNORE"
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
    
    if gh api "repos/$ORG/$repo/branches/$branch" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Deploy Dockerfile to a specific branch
deploy_to_branch() {
    local repo="$1"
    local branch="$2"
    local dockerfile="$3"
    local repo_type="$4"
    local dockerignore="$5"
    
    log_info "Deploying to branch: $branch"
    
    # Create unique temporary directory for this deployment
    local branch_temp_dir="$TEMP_DIR/${repo}_${branch}"
    mkdir -p "$branch_temp_dir"
    cd "$branch_temp_dir"
    
    # Clone the specific branch
    if ! gh repo clone "$ORG/$repo" . -- --branch "$branch" --single-branch &> /dev/null; then
        log_error "Failed to clone branch $branch from $repo"
        return 1
    fi
    
    # Configure git
    git config user.email "clmntmugisha@gmail.com"
    git config user.name "bikaze"
    
    # Copy the appropriate Dockerfile and .dockerignore
    cp "$dockerfile" ./Dockerfile
    cp "$dockerignore" ./.dockerignore
    
    # Add both files to staging area
    git add Dockerfile .dockerignore
    
    # Always commit and push (force update even if no changes detected)
    log_info "  📝 Updating Dockerfile and .dockerignore on $branch"
    
    # Commit changes (use --allow-empty to ensure commit even if no changes)
    git commit --allow-empty -m "Deploy optimized Dockerfile and .dockerignore for $repo_type project

- Add/update production-ready multi-stage Dockerfile
- Add/update .dockerignore for optimized builds
- Optimized for $repo_type deployment with multi-architecture support
- Automated deployment via deploy-dockerfiles.sh
- Branch: $branch
- Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" &> /dev/null
    
    # Push changes directly (admin privileges allow bypassing branch protection)
    if git push origin "$branch" &> /dev/null; then
        log_success "  ✓ Successfully deployed Docker files to $branch"
    else
        log_error "Failed to push Docker files to $branch"
        cd - &> /dev/null
        return 1
    fi
    
    cd - &> /dev/null
    return 0
}

# Deploy Dockerfile to a repository
deploy_to_repository() {
    local repo_input="$1"
    local repo_name repo_type dockerfile default_branch
    local successful_deployments=0
    local failed_deployments=0
    
    # Parse repository input
    if ! parse_repo_input "$repo_input"; then
        return 1
    fi
    
    repo_name="$REPO_NAME"
    repo_type="$REPO_TYPE"
    
    log_header "Deploying to $repo_name ($repo_type)"
    
    # Check if repository exists
    if ! check_repository_exists "$repo_name"; then
        log_error "Repository $ORG/$repo_name does not exist or is not accessible"
        return 1
    fi
    
    # Get the appropriate Dockerfile and .dockerignore
    if ! dockerfile=$(get_dockerfile "$repo_type"); then
        return 1
    fi
    
    if ! dockerignore=$(get_dockerignore "$repo_type"); then
        return 1
    fi
    
    log_success "Repository found: $ORG/$repo_name"
    log_info "Repository type: $repo_type"
    log_info "Using Dockerfile: $dockerfile"
    log_info "Using .dockerignore: $dockerignore"
    
    # Get default branch
    default_branch=$(get_default_branch "$repo_name")
    log_info "Default branch: $default_branch"
    
    # Deploy to each branch
    for branch in "${BRANCHES[@]}"; do
        if check_branch_exists "$repo_name" "$branch"; then
            if deploy_to_branch "$repo_name" "$branch" "$dockerfile" "$repo_type" "$dockerignore"; then
                ((successful_deployments++))
            else
                ((failed_deployments++))
            fi
        else
            log_warning "Branch '$branch' does not exist in $repo_name, skipping"
        fi
    done
    
    # Summary for this repository
    echo
    log_info "Repository summary:"
    log_info "  • Successful deployments: $successful_deployments"
    if [[ $failed_deployments -gt 0 ]]; then
        log_error "  • Failed deployments: $failed_deployments"
    fi
    
    return $failed_deployments
}

# Main deployment function
deploy_dockerfiles() {
    local total_repos=0
    local successful_repos=0
    local failed_repos=0
    
    log_header "Starting Dockerfile Deployment"
    
    # Validate dependencies and files
    validate_dependencies
    validate_dockerfile_files
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    log_info "Using temporary directory: $TEMP_DIR"
    
    # Deploy to each repository
    for repo_input in "${REPOS[@]}"; do
        ((total_repos++))
        
        if deploy_to_repository "$repo_input"; then
            ((successful_repos++))
        else
            ((failed_repos++))
        fi
        
        # Add separator between repositories (except for the last one)
        if [[ $total_repos -lt ${#REPOS[@]} ]]; then
            echo -e "\n${BLUE}────────────────────────────────────${NC}"
        fi
    done
    
    # Final summary
    echo
    log_header "Deployment Summary"
    log_info "Total repositories processed: $total_repos"
    log_success "Successful deployments: $successful_repos"
    
    if [[ $failed_repos -gt 0 ]]; then
        log_error "Failed deployments: $failed_repos"
        echo
        log_error "Some deployments failed. Please check the logs above for details."
        exit 1
    else
        echo
        log_success "🎉 All Dockerfiles deployed successfully!"
        log_info "All repositories now have optimized Docker configurations."
    fi
}

# Help function
show_help() {
    cat << EOF
🐳 Dockerfile Deployment Script

USAGE:
    $0 [OPTIONS]

DESCRIPTION:
    Deploys Dockerfiles and .dockerignore files to multiple repositories across development, staging, and production branches.
    
    This script:
    • Validates GitHub CLI authentication and dependencies
    • Deploys frontend Dockerfile + .dockerignore to frontend repositories
    • Deploys backend Dockerfile + .dockerignore to backend repositories  
    • Creates production-ready multi-stage Docker configurations with multi-architecture support
    • Optimizes build context with .dockerignore files
    • Handles branch protection bypassing (requires admin access)

REPOSITORIES:
    Frontend: cloudinsight-frontend-rw
    Backend:  cloudinsight-user-service-rw
              cloudinsight-cost-service-rw
              cloudinsight-metric-service-rw
              cloudinsight-anomaly-service-rw
              cloudinsight-forecast-service-rw
              cloudinsight-notification-service-rw

BRANCHES:
    • development
    • staging  
    • production

OPTIONS:
    -h, --help    Show this help message

EXAMPLES:
    $0              Deploy Dockerfiles to all repositories
    $0 --help       Show this help

REQUIREMENTS:
    • GitHub CLI (gh) installed and authenticated
    • Git installed
    • Admin access to target repositories
    • Internet connection

FILES:
    • frontend/Dockerfile - Next.js optimized multi-platform Dockerfile
    • frontend/.dockerignore - Frontend build optimization file
    • backend/Dockerfile  - Java Spring Boot optimized multi-platform Dockerfile
    • backend/.dockerignore - Backend build optimization file

EOF
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    "")
        deploy_dockerfiles
        ;;
    *)
        log_error "Unknown option: $1"
        echo
        show_help
        exit 1
        ;;
esac
