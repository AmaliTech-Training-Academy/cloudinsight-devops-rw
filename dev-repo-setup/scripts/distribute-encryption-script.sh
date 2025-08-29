#!/bin/bash

# Script to distribute encrypt-env-vars-team.sh to all team repositories
# Uses GitHub API to push the encryption script to all branches of specified repositories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ORG="AmaliTech-Training-Academy"
SCRIPT_NAME="encrypt-env-vars-team.sh"
TARGET_PATH="scripts/encrypt-env-vars-team.sh"
COMMIT_MESSAGE="Add team environment variables encryption script"
BRANCHES=("development" "staging" "production" "main")

# Repository list - combining all repositories from existing scripts
REPOS=(
    # API Gateway and Core Services
    "cloudinsight-api-gateway-rw:backend"
    "cloudinsight-service-discovery-rw:backend"
    "cloudinsight-config-server-rw:backend"
    "cloudinsight-config-repo-rw:backend"
    
    # Microservices
    "cloudinsight-user-service-rw:backend"
    "cloudinsight-cost-service-rw:backend"
    "cloudinsight-metric-service-rw:backend"
    "cloudinsight-anomaly-service-rw:backend"
    "cloudinsight-forecast-service-rw:backend"
    "cloudinsight-notification-service-rw:backend"
    
    # # Frontend
    "cloudinsight-frontend-rw:frontend"
    
    # Infrastructure (optional - uncomment if needed)
    # "cloudinsight-infrastructure-rw:backend"
    # "cloudinsight-monitoring-rw:backend"
    # "cloudinsight-ci-cd-rw:backend"
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

log_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

# Function to check if GitHub CLI is authenticated
check_gh_auth() {
    if ! gh auth status &>/dev/null; then
        log_error "GitHub CLI is not authenticated"
        log_info "Please run: gh auth login"
        exit 1
    fi
    log_success "GitHub CLI is authenticated"
}

# Function to check if local script exists
check_local_script() {
    if [[ ! -f "$SCRIPT_NAME" ]]; then
        log_error "Local script '$SCRIPT_NAME' not found"
        log_info "Please ensure you're running this from the scripts directory"
        exit 1
    fi
    log_success "Local script '$SCRIPT_NAME' found"
}

# Function to get repository name from repo string
get_repo_name() {
    echo "$1" | cut -d':' -f1
}

# Function to get repository type from repo string
get_repo_type() {
    echo "$1" | cut -d':' -f2
}

# Function to check if repository exists
check_repository_exists() {
    local repo="$1"
    if gh repo view "$ORG/$repo" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to get repository default branch
get_default_branch() {
    local repo="$1"
    gh api "repos/$ORG/$repo" --jq '.default_branch' 2>/dev/null || echo "main"
}

# Function to check if branch exists in repository
branch_exists() {
    local repo="$1"
    local branch="$2"
    
    if gh api "repos/$ORG/$repo/branches/$branch" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to get file SHA if it exists
get_file_sha() {
    local repo="$1"
    local branch="$2"
    local file_path="$3"
    
    gh api "repos/$ORG/$repo/contents/$file_path?ref=$branch" --jq '.sha' 2>/dev/null || echo ""
}

# Function to create scripts directory if it doesn't exist
ensure_scripts_directory() {
    local repo="$1"
    local branch="$2"
    
    # Check if scripts directory exists
    if ! gh api "repos/$ORG/$repo/contents/scripts?ref=$branch" &>/dev/null; then
        log_info "  Creating scripts directory in $repo on $branch..."
        
        # Create a placeholder file to create the directory
        echo "# Scripts Directory" | base64 > /tmp/readme_content
        
        gh api "repos/$ORG/$repo/contents/scripts/README.md" \
            --method PUT \
            --field message="Create scripts directory" \
            --field content="$(cat /tmp/readme_content)" \
            --field branch="$branch" &>/dev/null
        
        rm -f /tmp/readme_content
    fi
}

# Function to upload script to repository branch
upload_script_to_branch() {
    local repo="$1"
    local branch="$2"
    local file_content="$3"
    
    log_info "  📤 Uploading to $repo on $branch branch..."
    
    # Ensure scripts directory exists
    ensure_scripts_directory "$repo" "$branch"
    
    # Get existing file SHA if it exists
    local file_sha=$(get_file_sha "$repo" "$branch" "$TARGET_PATH")
    
    # Prepare API call
    local api_data='{
        "message": "'"$COMMIT_MESSAGE"'",
        "content": "'"$file_content"'",
        "branch": "'"$branch"'"
    }'
    
    # Add SHA if file exists (for update)
    if [[ -n "$file_sha" ]]; then
        api_data=$(echo "$api_data" | jq --arg sha "$file_sha" '. + {sha: $sha}')
        log_info "    Updating existing file..."
    else
        log_info "    Creating new file..."
    fi
    
    # Upload file
    if echo "$api_data" | gh api "repos/$ORG/$repo/contents/$TARGET_PATH" --method PUT --input - &>/dev/null; then
        log_success "    ✅ Successfully uploaded to $branch"
        return 0
    else
        log_error "    ❌ Failed to upload to $branch"
        return 1
    fi
}

# Function to process a single repository
process_repository() {
    local repo_info="$1"
    local repo_name=$(get_repo_name "$repo_info")
    local repo_type=$(get_repo_type "$repo_info")
    
    log_step "Processing $repo_name ($repo_type repository)"
    
    # Check if repository exists
    if ! check_repository_exists "$repo_name"; then
        log_warning "  Repository $repo_name does not exist, skipping..."
        return 1
    fi
    
    # Get default branch
    local default_branch=$(get_default_branch "$repo_name")
    log_info "  Default branch: $default_branch"
    
    # Process each branch
    local success_count=0
    local total_branches=0
    
    for branch in "${BRANCHES[@]}"; do
        if branch_exists "$repo_name" "$branch"; then
            ((total_branches++))
            if upload_script_to_branch "$repo_name" "$branch" "$file_content"; then
                ((success_count++))
            fi
        else
            log_warning "  Branch '$branch' does not exist in $repo_name"
        fi
    done
    
    if [[ $success_count -gt 0 ]]; then
        log_success "  📊 Successfully updated $success_count/$total_branches branches in $repo_name"
        return 0
    else
        log_error "  📊 Failed to update any branches in $repo_name"
        return 1
    fi
}

# Function to show summary
show_summary() {
    local successful_repos=("$@")
    
    echo
    log_step "📊 Deployment Summary"
    echo "=================================="
    
    if [[ ${#successful_repos[@]} -gt 0 ]]; then
        log_success "Successfully updated ${#successful_repos[@]} repositories:"
        for repo in "${successful_repos[@]}"; do
            echo "  ✅ $repo"
        done
    fi
    
    local failed_count=$((${#REPOS[@]} - ${#successful_repos[@]}))
    if [[ $failed_count -gt 0 ]]; then
        log_warning "Failed to update $failed_count repositories"
    fi
    
    echo
    log_info "🔗 Next steps for developers:"
    echo "  1. Clone or pull latest changes from their repositories"
    echo "  2. Navigate to the scripts/ directory"
    echo "  3. Run: chmod +x encrypt-env-vars-team.sh"
    echo "  4. Use: ./encrypt-env-vars-team.sh to encrypt their .env files"
    
    echo
    log_info "📖 Full documentation available at:"
    echo "  https://github.com/$ORG/cloudinsight-devops-rw/blob/main/dev-repo-setup/scripts/README-TEAM-ENCRYPTION.md"
}

# Main function
main() {
    echo
    log_step "🚀 Team Encryption Script Distribution"
    echo "======================================="
    echo
    
    # Pre-flight checks
    log_step "Pre-flight checks..."
    check_gh_auth
    check_local_script
    
    # Prepare script content (base64 encoded for API)
    log_step "Preparing script content..."
    file_content=$(base64 -w 0 "$SCRIPT_NAME")
    log_success "Script content prepared"
    
    # Show what will be deployed
    echo
    log_step "Deployment plan:"
    echo "  📄 Script: $SCRIPT_NAME"
    echo "  📍 Target path: $TARGET_PATH"
    echo "  🌿 Branches: ${BRANCHES[*]}"
    echo "  📦 Repositories: ${#REPOS[@]} total"
    echo
    
    # Confirm deployment
    read -p "🤔 Do you want to proceed with the deployment? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warning "Deployment cancelled by user"
        exit 0
    fi
    
    # Process each repository
    echo
    log_step "🎯 Starting deployment..."
    
    successful_repos=()
    
    for repo_info in "${REPOS[@]}"; do
        echo
        if process_repository "$repo_info"; then
            repo_name=$(get_repo_name "$repo_info")
            successful_repos+=("$repo_name")
        fi
    done
    
    # Show summary
    show_summary "${successful_repos[@]}"
    
    echo
    if [[ ${#successful_repos[@]} -eq ${#REPOS[@]} ]]; then
        log_success "🎉 All repositories updated successfully!"
    elif [[ ${#successful_repos[@]} -gt 0 ]]; then
        log_warning "⚠️  Partial success: ${#successful_repos[@]}/${#REPOS[@]} repositories updated"
    else
        log_error "💥 No repositories were updated successfully"
        exit 1
    fi
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
