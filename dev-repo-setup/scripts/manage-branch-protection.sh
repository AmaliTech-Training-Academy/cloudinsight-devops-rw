#!/bin/bash

# Branch Protection Management Script
# This script applies or removes branch protection rules for CloudInsight repositories
# Author: DevOps Team
# Version: 1.0

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Organization
ORG="AmaliTech-Training-Academy"

# Repository configuration
# Format: "repo_name:type" where type is either "frontend" or "backend"
# Import the same repository list from create-repos.sh
REPOS=(
#   "cloudinsight-devops-rw:backend"
#   "cloudinsight-backend-rw:backend"
    "cloudinsight-user-service-rw:backend"
    "cloudinsight-cost-service-rw:backend"
    "cloudinsight-metric-service-rw:backend"
    "cloudinsight-anomaly-service-rw:backend"
    "cloudinsight-forecast-service-rw:backend"
    "cloudinsight-notification-service-rw:backend"
  # "cloudinsight-frontend-rw:frontend"
#   "cloudinsight-infrastructure-rw:backend"
#   "cloudinsight-monitoring-rw:backend"
#   "cloudinsight-ci-cd-rw:backend"
)

# Branch configuration
BRANCHES=("development" "staging" "production")

# Utility functions
log_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Function to check if gh CLI is installed and authenticated
check_gh_cli() {
  if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is not installed. Please install it first."
    echo "Visit: https://cli.github.com/"
    exit 1
  fi

  if ! gh auth status &> /dev/null; then
    log_error "GitHub CLI is not authenticated. Please run 'gh auth login' first."
    exit 1
  fi

  log_success "GitHub CLI is installed and authenticated"
}

# Function to get repository name
get_repo_name() {
  local REPO_CONFIG=$1
  echo "${REPO_CONFIG%%:*}"
}

# Function to get repository type
get_repo_type() {
  local REPO_CONFIG=$1
  echo "${REPO_CONFIG##*:}"
}

# Function to check if repository exists
repo_exists() {
  local REPO=$1
  if gh repo view "$ORG/$REPO" &> /dev/null; then
    return 0
  else
    return 1
  fi
}

# Function to check if branch exists
branch_exists() {
  local repo="$1"
  local branch="$2"
  gh api "/repos/$ORG/$repo/branches/$branch" >/dev/null 2>&1
}

# Function to check if branch is protected
is_branch_protected() {
  local repo="$1"
  local branch="$2"
  gh api "/repos/$ORG/$repo/branches/$branch/protection" >/dev/null 2>&1
}

# Function to get existing status checks to preserve them
get_existing_status_checks() {
  local repo="$1"
  local branch="$2"
  
  local existing_checks
  existing_checks=$(gh api "/repos/$ORG/$repo/branches/$branch/protection" \
      --jq '.required_status_checks.contexts[]' 2>/dev/null | tr '\n' ' ' || echo "")
  
  echo "$existing_checks"
}

# Function to apply branch protection using proper JSON payload
protect_branch() {
  local repo="$1"
  local branch="$2"
  local branch_type="$3" # development, staging, or production
  
  if ! branch_exists "$repo" "$branch"; then
    log_warning "Branch '$branch' does not exist in $repo, skipping protection"
    return 1
  fi
  
  # Get existing status checks to preserve them
  local existing_checks
  existing_checks=$(get_existing_status_checks "$repo" "$branch")
  
  # Set protection level based on branch type
  local required_reviews=1
  
  case "$branch_type" in
    "development")
      required_reviews=1
      log_info "Protecting $repo:$branch (Development branch: $required_reviews approval, code owners required)"
      ;;
    "staging")
      required_reviews=1
      log_info "Protecting $repo:$branch (Staging branch: $required_reviews approval, code owners required)"
      ;;
    "production")
      required_reviews=1
      log_info "Protecting $repo:$branch (Production branch: $required_reviews approval, code owners required)"
      ;;
    *)
      log_warning "Unknown branch type: $branch_type. Using default protection (1 approval)"
      ;;
  esac
  
  # Build JSON payload with protection rules
  local payload="{
    \"required_status_checks\": {
      \"strict\": true,
      \"contexts\": []
    },
    \"enforce_admins\": false,
    \"required_pull_request_reviews\": {
      \"required_approving_review_count\": $required_reviews,
      \"dismiss_stale_reviews\": true,
      \"require_code_owner_reviews\": true,
      \"require_last_push_approval\": true
    },
    \"restrictions\": null,
    \"allow_force_pushes\": false,
    \"allow_deletions\": false,
    \"required_conversation_resolution\": true
  }"
  
  # Apply the protection
  if echo "$payload" | gh api -X PUT "/repos/$ORG/$repo/branches/$branch/protection" --input - >/dev/null 2>&1; then
    log_success "✓ Protected $repo:$branch"
    
    # If we had existing status checks, try to preserve them
    if [[ -n "$existing_checks" ]]; then
      local update_payload="{\"strict\": true, \"contexts\": [$(echo "$existing_checks" | sed 's/ /", "/g' | sed 's/^/"/; s/$/"/' | sed 's/", "$/"/')]}"
      if echo "$update_payload" | gh api -X PATCH "/repos/$ORG/$repo/branches/$branch/protection/required_status_checks" --input - >/dev/null 2>&1; then
        log_info "  ✓ Preserved existing status checks"
      fi
    fi
    return 0
  else
    log_error "✗ Failed to protect $repo:$branch"
    return 1
  fi
}

# Function to remove branch protection
remove_branch_protection() {
  local repo="$1"
  local branch="$2"
  
  if ! branch_exists "$repo" "$branch"; then
    log_warning "Branch '$branch' does not exist in $repo, skipping"
    return 1
  fi
  
  if ! is_branch_protected "$repo" "$branch"; then
    log_info "$repo:$branch is not protected, skipping"
    return 0
  fi
  
  log_info "Removing protection from $repo:$branch"
  
  if gh api --method DELETE "/repos/$ORG/$repo/branches/$branch/protection" &> /dev/null; then
    log_success "✓ Removed protection from $repo:$branch"
    return 0
  else
    log_error "✗ Failed to remove protection from $repo:$branch"
    return 1
  fi
}

# Function to enable CODEOWNERS enforcement for a repository
enable_codeowners() {
  local repo="$1"
  
  log_info "Enabling CODEOWNERS functionality for $repo"
  local success_count=0
  
  for branch in "${BRANCHES[@]}"; do
    if branch_exists "$repo" "$branch"; then
      if protect_branch "$repo" "$branch" "$branch"; then
        ((success_count++))
      fi
    fi
  done
  
  if [[ $success_count -eq ${#BRANCHES[@]} ]]; then
    log_success "✓ CODEOWNERS enforcement enabled for all branches in $repo"
    return 0
  elif [[ $success_count -gt 0 ]]; then
    log_warning "⚠️ CODEOWNERS enforcement enabled for some branches in $repo"
    return 0
  else
    log_error "✗ Failed to enable CODEOWNERS enforcement for $repo"
    return 1
  fi
}

# Function to disable CODEOWNERS enforcement for a repository
disable_codeowners() {
  local repo="$1"
  
  log_info "Disabling CODEOWNERS functionality for $repo"
  local success_count=0
  
  for branch in "${BRANCHES[@]}"; do
    if branch_exists "$repo" "$branch"; then
      if remove_branch_protection "$repo" "$branch"; then
        ((success_count++))
      fi
    fi
  done
  
  if [[ $success_count -eq ${#BRANCHES[@]} ]]; then
    log_success "✓ CODEOWNERS enforcement disabled for all branches in $repo"
    return 0
  elif [[ $success_count -gt 0 ]]; then
    log_warning "⚠️ CODEOWNERS enforcement disabled for some branches in $repo"
    return 0
  else
    log_error "✗ Failed to disable CODEOWNERS enforcement for $repo"
    return 1
  fi
}

# Function to apply protection to all repositories
enable_all_protection() {
  log_info "Starting protection setup for all repositories..."
  
  local total_repos=${#REPOS[@]}
  local current_repo=0
  local success_count=0
  local failed_repos=()
  
  for REPO_CONFIG in "${REPOS[@]}"; do
    current_repo=$((current_repo + 1))
    
    # Extract repo name and type
    REPO=$(get_repo_name "$REPO_CONFIG")
    REPO_TYPE=$(get_repo_type "$REPO_CONFIG")
    
    echo
    echo "=================================================="
    log_info "Processing repository $current_repo/$total_repos: $REPO ($REPO_TYPE)"
    echo "=================================================="
    
    # Check if repository exists
    if ! repo_exists "$REPO"; then
      log_warning "Repository $REPO does not exist, skipping"
      failed_repos+=("$REPO ($REPO_TYPE) - does not exist")
      continue
    fi
    
    if enable_codeowners "$REPO"; then
      success_count=$((success_count + 1))
    else
      failed_repos+=("$REPO ($REPO_TYPE)")
    fi
  done
  
  # Summary
  echo
  echo "=================================================="
  log_info "BRANCH PROTECTION SUMMARY"
  echo "=================================================="
  log_success "Successfully protected: $success_count/$total_repos repositories"
  
  if [[ ${#failed_repos[@]} -gt 0 ]]; then
    log_warning "Failed repositories:"
    for failed_repo in "${failed_repos[@]}"; do
      echo "  - $failed_repo"
    done
  fi
  
  echo
  log_success "Branch protection process completed!"
}

# Function to remove protection from all repositories
disable_all_protection() {
  log_info "Starting removal of branch protection for all repositories..."
  
  local total_repos=${#REPOS[@]}
  local current_repo=0
  local success_count=0
  local failed_repos=()
  
  for REPO_CONFIG in "${REPOS[@]}"; do
    current_repo=$((current_repo + 1))
    
    # Extract repo name and type
    REPO=$(get_repo_name "$REPO_CONFIG")
    REPO_TYPE=$(get_repo_type "$REPO_CONFIG")
    
    echo
    echo "=================================================="
    log_info "Processing repository $current_repo/$total_repos: $REPO ($REPO_TYPE)"
    echo "=================================================="
    
    # Check if repository exists
    if ! repo_exists "$REPO"; then
      log_warning "Repository $REPO does not exist, skipping"
      failed_repos+=("$REPO ($REPO_TYPE) - does not exist")
      continue
    fi
    
    if disable_codeowners "$REPO"; then
      success_count=$((success_count + 1))
    else
      failed_repos+=("$REPO ($REPO_TYPE)")
    fi
  done
  
  # Summary
  echo
  echo "=================================================="
  log_info "BRANCH PROTECTION REMOVAL SUMMARY"
  echo "=================================================="
  log_success "Successfully processed: $success_count/$total_repos repositories"
  
  if [[ ${#failed_repos[@]} -gt 0 ]]; then
    log_warning "Failed repositories:"
    for failed_repo in "${failed_repos[@]}"; do
      echo "  - $failed_repo"
    done
  fi
  
  echo
  log_success "Branch protection removal process completed!"
}

# Function to show current protection status
show_protection_status() {
  echo "🔍 Current Branch Protection Status"
  echo "=================================="
  echo
  
  for REPO_CONFIG in "${REPOS[@]}"; do
    # Extract repo name and type
    REPO=$(get_repo_name "$REPO_CONFIG")
    REPO_TYPE=$(get_repo_type "$REPO_CONFIG")
    
    # Check if repository exists
    if ! repo_exists "$REPO"; then
      log_warning "Repository $REPO ($REPO_TYPE) does not exist, skipping"
      continue
    fi
    
    echo "Repository: $REPO ($REPO_TYPE)"
    
    for branch in "${BRANCHES[@]}"; do
      if branch_exists "$REPO" "$branch"; then
        if is_branch_protected "$REPO" "$branch"; then
          # Try to get review count for more info
          local review_count=$(gh api "/repos/$ORG/$REPO/branches/$branch/protection" \
            --jq '.required_pull_request_reviews.required_approving_review_count' 2>/dev/null || echo "?")
          
          # Check if code owner reviews are required
          local code_owners_required=$(gh api "/repos/$ORG/$REPO/branches/$branch/protection" \
            --jq '.required_pull_request_reviews.require_code_owner_reviews' 2>/dev/null || echo "?")
          
          echo "  ✅ $branch - Protected ($review_count approval(s), CODEOWNERS: $code_owners_required)"
        else
          echo "  ❌ $branch - Not Protected"
        fi
      else
        echo "  ⚠️  $branch - Branch doesn't exist"
      fi
    done
    echo
  done
}

# Function to show help
show_help() {
  echo "Branch Protection Management Script"
  echo "=================================="
  echo
  echo "This script applies or removes branch protection rules for CloudInsight repositories."
  echo
  echo "Protection Rules Applied:"
  echo "  All branches (development, staging, production):"
  echo "    - 1 approval required"
  echo "    - Code owner reviews required"
  echo "    - Dismiss stale reviews enabled"
  echo "    - Conversation resolution required"
  echo "    - Force pushes blocked"
  echo "    - Branch deletions blocked"
  echo
  echo "Repositories that will be managed:"
  for REPO_CONFIG in "${REPOS[@]}"; do
    REPO=$(get_repo_name "$REPO_CONFIG")
    REPO_TYPE=$(get_repo_type "$REPO_CONFIG")
    echo "  - $REPO ($REPO_TYPE)"
  done
  echo
  echo "Usage:"
  echo "  $0 [OPTION]"
  echo
  echo "Options:"
  echo "  --help         Show this help message"
  echo "  --status       Show current protection status of all repositories"
  echo "  --enable       Enable branch protection and CODEOWNERS enforcement for all repositories"
  echo "  --disable      Remove branch protection from all repositories"
  echo "  --repo REPO    Operate on a specific repository only (use with --enable or --disable)"
  echo
  echo "Examples:"
  echo "  $0 --status                    Show protection status for all repositories"
  echo "  $0 --enable                    Enable protection for all repositories"
  echo "  $0 --disable                   Disable protection for all repositories"
  echo "  $0 --enable --repo cloudinsight-frontend-rw    Enable protection for a specific repository"
  echo
  echo "Prerequisites:"
  echo "  - GitHub CLI (gh) must be installed and authenticated"
  echo "  - You must have admin access to the repositories in $ORG organization"
  echo
  echo "Note:"
  echo "  This script requires the CODEOWNERS files to be properly set up in each repository."
  echo "  Use the create-repos.sh script first to set up the repositories with proper CODEOWNERS files."
  echo
}

# Main function
main() {
  # Check for help flag or no arguments
  if [[ "$#" -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
  fi
  
  # Check prerequisites
  log_info "Checking prerequisites..."
  check_gh_cli
  
  # Parse command-line options
  local ACTION=""
  local SPECIFIC_REPO=""
  
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      "--status")
        ACTION="status"
        shift
        ;;
      "--enable")
        ACTION="enable"
        shift
        ;;
      "--disable")
        ACTION="disable"
        shift
        ;;
      "--repo")
        if [[ "$#" -lt 2 ]]; then
          log_error "Missing repository name after --repo"
          exit 1
        fi
        SPECIFIC_REPO="$2"
        shift 2
        ;;
      *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
  done
  
  # Process based on action
  case "$ACTION" in
    "status")
      show_protection_status
      ;;
    "enable")
      if [[ -n "$SPECIFIC_REPO" ]]; then
        # Check if the specified repo exists in our list
        local REPO_TYPE=""
        local REPO_EXISTS=false
        
        for REPO_CONFIG in "${REPOS[@]}"; do
          if [[ "$(get_repo_name "$REPO_CONFIG")" == "$SPECIFIC_REPO" ]]; then
            REPO_TYPE=$(get_repo_type "$REPO_CONFIG")
            REPO_EXISTS=true
            break
          fi
        done
        
        if [[ "$REPO_EXISTS" == "true" ]]; then
          echo "🔐 Enabling Branch Protection for: $SPECIFIC_REPO ($REPO_TYPE)"
          echo "=============================================="
          echo
          
          if repo_exists "$SPECIFIC_REPO"; then
            enable_codeowners "$SPECIFIC_REPO"
          else
            log_error "Repository $SPECIFIC_REPO does not exist in $ORG organization"
            exit 1
          fi
        else
          log_error "Repository $SPECIFIC_REPO is not in the configured list of repositories"
          echo "Use one of the following repositories:"
          for REPO_CONFIG in "${REPOS[@]}"; do
            echo "  - $(get_repo_name "$REPO_CONFIG")"
          done
          exit 1
        fi
      else
        echo "🔐 Enabling Branch Protection for All Repositories"
        echo "=============================================="
        echo
        
        log_info "This script will apply branch protection rules for:"
        echo "  Total repositories: ${#REPOS[@]}"
        echo
        log_warning "This will enable branch protection and CODEOWNERS enforcement!"
        
        echo
        read -p "Do you want to continue? (y/N): " REPLY
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          log_warning "Operation cancelled by user"
          exit 0
        fi
        
        enable_all_protection
      fi
      ;;
    "disable")
      if [[ -n "$SPECIFIC_REPO" ]]; then
        # Check if the specified repo exists in our list
        local REPO_TYPE=""
        local REPO_EXISTS=false
        
        for REPO_CONFIG in "${REPOS[@]}"; do
          if [[ "$(get_repo_name "$REPO_CONFIG")" == "$SPECIFIC_REPO" ]]; then
            REPO_TYPE=$(get_repo_type "$REPO_CONFIG")
            REPO_EXISTS=true
            break
          fi
        done
        
        if [[ "$REPO_EXISTS" == "true" ]]; then
          echo "🔓 Disabling Branch Protection for: $SPECIFIC_REPO ($REPO_TYPE)"
          echo "=============================================="
          echo
          
          if repo_exists "$SPECIFIC_REPO"; then
            disable_codeowners "$SPECIFIC_REPO"
          else
            log_error "Repository $SPECIFIC_REPO does not exist in $ORG organization"
            exit 1
          fi
        else
          log_error "Repository $SPECIFIC_REPO is not in the configured list of repositories"
          echo "Use one of the following repositories:"
          for REPO_CONFIG in "${REPOS[@]}"; do
            echo "  - $(get_repo_name "$REPO_CONFIG")"
          done
          exit 1
        fi
      else
        echo "🔓 Disabling Branch Protection for All Repositories"
        echo "=============================================="
        echo
        
        log_info "This script will remove branch protection rules for:"
        echo "  Total repositories: ${#REPOS[@]}"
        echo
        log_warning "WARNING: This will remove all branch protection rules!"
        log_warning "CODEOWNERS files will remain but will not be enforced!"
        
        echo
        read -p "Do you want to continue? (y/N): " REPLY
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          log_warning "Operation cancelled by user"
          exit 0
        fi
        
        disable_all_protection
      fi
      ;;
    *)
      log_error "No action specified. Use --status, --enable, or --disable"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
}

# Run the script
main "$@"
