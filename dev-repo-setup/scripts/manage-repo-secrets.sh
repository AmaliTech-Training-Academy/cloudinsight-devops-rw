#!/bin/bash

# Script to manage GitHub repository secrets across multiple repositories
# Allows interactive input of secrets and applies them to all specified repositories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ORG="AmaliTech-Training-Academy"

# Repository list - using same repos as distribution script
REPOS=(
    # API Gateway and Core Services
    "cloudinsight-api-gateway-rw:backend"
    "cloudinsight-service-discovery-rw:backend"
    "cloudinsight-config-server-rw:backend"
    
    # # Microservices
    "cloudinsight-user-service-rw:backend"
    "cloudinsight-cost-service-rw:backend"
    "cloudinsight-metric-service-rw:backend"
    "cloudinsight-anomaly-service-rw:backend"
    "cloudinsight-forecast-service-rw:backend"
    "cloudinsight-notification-service-rw:backend"
    
    # Frontend
    # "cloudinsight-frontend-rw:frontend"
    
    # Infrastructure (uncomment if needed)
    # "cloudinsight-infrastructure-rw:backend"
    # "cloudinsight-monitoring-rw:backend"
    # "cloudinsight-ci-cd-rw:backend"
)

# Global arrays to store secrets
declare -a SECRET_NAMES
declare -a SECRET_VALUES
declare -a SECRET_DESCRIPTIONS

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
    echo -e "${CYAN}📋 $1${NC}"
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

# Function to validate secret name
validate_secret_name() {
    local name="$1"
    
    # Check if name is empty
    if [[ -z "$name" ]]; then
        return 1
    fi
    
    # Check if name contains only valid characters (A-Z, 0-9, _)
    if [[ ! "$name" =~ ^[A-Z0-9_]+$ ]]; then
        log_error "Secret name must contain only uppercase letters, numbers, and underscores"
        return 1
    fi
    
    # Check if name starts with GITHUB_ (reserved)
    if [[ "$name" =~ ^GITHUB_ ]]; then
        log_error "Secret names cannot start with 'GITHUB_' (reserved prefix)"
        return 1
    fi
    
    return 0
}

# Function to check if secret name already exists in our list
secret_name_exists() {
    local name="$1"
    for existing_name in "${SECRET_NAMES[@]}"; do
        if [[ "$existing_name" == "$name" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to input a single secret
input_secret() {
    local secret_num="$1"
    
    echo
    log_step "Secret #$secret_num Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get secret name
    local secret_name=""
    while true; do
        echo
        read -p "🏷️  Enter secret name (uppercase, A-Z, 0-9, _ only): " secret_name
        
        if [[ -z "$secret_name" ]]; then
            log_warning "Secret name cannot be empty"
            continue
        fi
        
        # Convert to uppercase
        secret_name=$(echo "$secret_name" | tr '[:lower:]' '[:upper:]')
        
        if ! validate_secret_name "$secret_name"; then
            continue
        fi
        
        if secret_name_exists "$secret_name"; then
            log_warning "Secret '$secret_name' already exists in the list"
            continue
        fi
        
        break
    done
    
    # Get secret value (hidden input)
    local secret_value=""
    while [[ -z "$secret_value" ]]; do
        echo
        read -s -p "🔐 Enter secret value for '$secret_name' (hidden): " secret_value
        echo
        
        if [[ -z "$secret_value" ]]; then
            log_warning "Secret value cannot be empty"
        fi
    done
    
    # Get optional description
    echo
    read -p "📝 Enter description (optional): " secret_description
    
    # Store the secret
    SECRET_NAMES+=("$secret_name")
    SECRET_VALUES+=("$secret_value")
    SECRET_DESCRIPTIONS+=("$secret_description")
    
    log_success "Secret '$secret_name' configured"
}

# Function to collect all secrets from user
collect_secrets() {
    log_step "Secret Collection Phase"
    echo "=========================================="
    
    log_info "You can add multiple secrets that will be applied to all repositories"
    log_warning "Note: Secret names will be converted to UPPERCASE automatically"
    
    local secret_count=1
    
    while true; do
        input_secret "$secret_count"
        
        echo
        echo "Current secrets configured: $secret_count"
        for i in "${!SECRET_NAMES[@]}"; do
            local desc="${SECRET_DESCRIPTIONS[$i]}"
            if [[ -n "$desc" ]]; then
                echo "  $((i+1)). ${SECRET_NAMES[$i]} - $desc"
            else
                echo "  $((i+1)). ${SECRET_NAMES[$i]}"
            fi
        done
        
        echo
        read -p "🤔 Do you want to add another secret? (y/N): " add_more
        
        if [[ ! "$add_more" =~ ^[Yy]$ ]]; then
            break
        fi
        
        ((secret_count++))
    done
    
    echo
    log_success "Total secrets configured: ${#SECRET_NAMES[@]}"
}

# Function to show secrets summary
show_secrets_summary() {
    echo
    log_step "Secrets Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ ${#SECRET_NAMES[@]} -eq 0 ]]; then
        log_warning "No secrets configured"
        return
    fi
    
    for i in "${!SECRET_NAMES[@]}"; do
        local name="${SECRET_NAMES[$i]}"
        local value="${SECRET_VALUES[$i]}"
        local desc="${SECRET_DESCRIPTIONS[$i]}"
        local masked_value=$(echo "$value" | sed 's/./*/g' | cut -c1-20)
        
        echo "  $((i+1)). $name"
        echo "     Value: $masked_value (${#value} characters)"
        if [[ -n "$desc" ]]; then
            echo "     Description: $desc"
        fi
        echo
    done
}

# Function to set secret in a repository
set_repository_secret() {
    local repo="$1"
    local secret_name="$2"
    local secret_value="$3"
    
    log_info "  Setting '$secret_name' in $repo..."
    
    if echo "$secret_value" | gh secret set "$secret_name" --repo "$ORG/$repo" 2>/dev/null; then
        log_success "    ✅ Successfully set '$secret_name'"
        return 0
    else
        log_error "    ❌ Failed to set '$secret_name'"
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
    
    local success_count=0
    local total_secrets=${#SECRET_NAMES[@]}
    
    # Set each secret
    for i in "${!SECRET_NAMES[@]}"; do
        local secret_name="${SECRET_NAMES[$i]}"
        local secret_value="${SECRET_VALUES[$i]}"
        
        if set_repository_secret "$repo_name" "$secret_name" "$secret_value"; then
            ((success_count++))
        fi
    done
    
    if [[ $success_count -eq $total_secrets ]]; then
        log_success "  📊 Successfully set all $total_secrets secrets in $repo_name"
        return 0
    else
        log_error "  📊 Set $success_count/$total_secrets secrets in $repo_name"
        return 1
    fi
}

# Function to show deployment summary
show_deployment_summary() {
    local successful_repos=("$@")
    
    echo
    log_step "📊 Deployment Summary"
    echo "=================================="
    
    local total_repos=${#REPOS[@]}
    local successful_count=${#successful_repos[@]}
    
    echo "📈 Statistics:"
    echo "  • Total repositories: $total_repos"
    echo "  • Successful deployments: $successful_count"
    echo "  • Failed deployments: $((total_repos - successful_count))"
    echo "  • Total secrets per repo: ${#SECRET_NAMES[@]}"
    echo
    
    if [[ $successful_count -gt 0 ]]; then
        log_success "Successfully updated repositories:"
        for repo in "${successful_repos[@]}"; do
            echo "  ✅ $repo"
        done
        echo
    fi
    
    local failed_count=$((total_repos - successful_count))
    if [[ $failed_count -gt 0 ]]; then
        log_warning "Failed repositories: $failed_count"
        echo
    fi
    
    echo "🔍 Secrets deployed:"
    for name in "${SECRET_NAMES[@]}"; do
        echo "  🔑 $name"
    done
    
    echo
    log_info "🚀 Next steps:"
    echo "  • Secrets are now available in GitHub Actions workflows"
    echo "  • Use secrets in workflows: \${{ secrets.SECRET_NAME }}"
    echo "  • View secrets in repository Settings → Secrets and variables → Actions"
}

# Function to confirm deployment
confirm_deployment() {
    echo
    log_step "Deployment Confirmation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo "📋 Deployment Plan:"
    echo "  • Organization: $ORG"
    echo "  • Repositories: ${#REPOS[@]} total"
    echo "  • Secrets per repository: ${#SECRET_NAMES[@]}"
    echo "  • Total operations: $((${#REPOS[@]} * ${#SECRET_NAMES[@]}))"
    echo
    
    echo "🎯 Target repositories:"
    for repo_info in "${REPOS[@]}"; do
        local repo_name=$(get_repo_name "$repo_info")
        local repo_type=$(get_repo_type "$repo_info")
        echo "  • $repo_name ($repo_type)"
    done
    
    echo
    log_warning "⚠️  This will overwrite any existing secrets with the same names!"
    echo
    
    read -p "🤔 Do you want to proceed with the deployment? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warning "Deployment cancelled by user"
        exit 0
    fi
    
    log_success "Deployment confirmed!"
}

# Main function
main() {
    echo
    log_step "🔐 GitHub Repository Secrets Manager"
    echo "======================================="
    echo
    
    # Pre-flight checks
    log_step "Pre-flight checks..."
    check_gh_auth
    
    # Collect secrets from user
    collect_secrets
    
    # Show summary
    show_secrets_summary
    
    # Confirm deployment
    confirm_deployment
    
    # Deploy secrets
    echo
    log_step "🚀 Starting secrets deployment..."
    
    successful_repos=()
    
    for repo_info in "${REPOS[@]}"; do
        echo
        if process_repository "$repo_info"; then
            repo_name=$(get_repo_name "$repo_info")
            successful_repos+=("$repo_name")
        fi
    done
    
    # Show final summary
    show_deployment_summary "${successful_repos[@]}"
    
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

# Help function
show_help() {
    echo "GitHub Repository Secrets Manager"
    echo
    echo "USAGE:"
    echo "  $0 [OPTIONS]"
    echo
    echo "DESCRIPTION:"
    echo "  Interactive script to set GitHub repository secrets across multiple repositories."
    echo "  The script will prompt you to enter secret names and values, then apply them"
    echo "  to all repositories defined in the REPOS array."
    echo
    echo "OPTIONS:"
    echo "  -h, --help    Show this help message"
    echo
    echo "FEATURES:"
    echo "  • Interactive secret collection"
    echo "  • Input validation (secret names must be uppercase, A-Z, 0-9, _ only)"
    echo "  • Hidden password input"
    echo "  • Bulk deployment to multiple repositories"
    echo "  • Detailed progress reporting"
    echo "  • Deployment confirmation before execution"
    echo
    echo "EXAMPLES:"
    echo "  $0                    # Interactive mode (recommended)"
    echo "  $0 --help           # Show this help"
    echo
    echo "REPOSITORIES:"
    echo "  The script will deploy secrets to these repositories:"
    for repo_info in "${REPOS[@]}"; do
        local repo_name=$(get_repo_name "$repo_info")
        local repo_type=$(get_repo_type "$repo_info")
        echo "    • $repo_name ($repo_type)"
    done
    echo
    echo "SECURITY NOTES:"
    echo "  • Secret values are hidden during input"
    echo "  • Secrets are transmitted securely via GitHub CLI"
    echo "  • Existing secrets with same names will be overwritten"
    echo "  • Requires admin access to target repositories"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    "")
        # No arguments, run main function
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
