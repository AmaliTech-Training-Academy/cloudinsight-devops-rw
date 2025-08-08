#!/bin/bash

# Repository Visibility Management Script
# This script changes visibility (public/private) for CloudInsight repositories
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
  "cloudinsight-frontend-rw:frontend"
#   "cloudinsight-infrastructure-rw:backend"
#   "cloudinsight-monitoring-rw:backend"
#   "cloudinsight-ci-cd-rw:backend"
)

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

# Function to get current visibility of repository
get_repo_visibility() {
  local REPO=$1
  local visibility=$(gh api "/repos/$ORG/$REPO" --jq '.visibility' 2>/dev/null)
  echo "$visibility"
}

# Function to change repository visibility
change_repo_visibility() {
  local REPO=$1
  local NEW_VISIBILITY=$2
  local CURRENT_VISIBILITY=$(get_repo_visibility "$REPO")
  
  # Check if visibility change is needed
  if [[ "$CURRENT_VISIBILITY" == "$NEW_VISIBILITY" ]]; then
    log_info "Repository $REPO is already $NEW_VISIBILITY"
    return 0
  fi
  
  log_info "Changing visibility of $REPO from $CURRENT_VISIBILITY to $NEW_VISIBILITY..."
  
  if gh api --method PATCH "/repos/$ORG/$REPO" -f visibility="$NEW_VISIBILITY" &> /dev/null; then
    log_success "✓ Changed $REPO visibility to $NEW_VISIBILITY"
    return 0
  else
    log_error "✗ Failed to change $REPO visibility to $NEW_VISIBILITY"
    return 1
  fi
}

# Function to make a specific repository public
make_repo_public() {
  local REPO=$1
  
  if ! repo_exists "$REPO"; then
    log_error "Repository $REPO does not exist in $ORG organization"
    return 1
  fi
  
  change_repo_visibility "$REPO" "public"
}

# Function to make a specific repository private
make_repo_private() {
  local REPO=$1
  
  if ! repo_exists "$REPO"; then
    log_error "Repository $REPO does not exist in $ORG organization"
    return 1
  fi
  
  change_repo_visibility "$REPO" "private"
}

# Function to make all repositories public
make_all_repos_public() {
  log_info "Making all repositories public..."
  
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
    
    if make_repo_public "$REPO"; then
      success_count=$((success_count + 1))
    else
      failed_repos+=("$REPO ($REPO_TYPE)")
    fi
  done
  
  # Summary
  echo
  echo "=================================================="
  log_info "VISIBILITY CHANGE SUMMARY"
  echo "=================================================="
  log_success "Successfully made public: $success_count/$total_repos repositories"
  
  if [[ ${#failed_repos[@]} -gt 0 ]]; then
    log_warning "Failed repositories:"
    for failed_repo in "${failed_repos[@]}"; do
      echo "  - $failed_repo"
    done
  fi
  
  echo
  log_success "Repository visibility change process completed!"
}

# Function to make all repositories private
make_all_repos_private() {
  log_info "Making all repositories private..."
  
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
    
    if make_repo_private "$REPO"; then
      success_count=$((success_count + 1))
    else
      failed_repos+=("$REPO ($REPO_TYPE)")
    fi
  done
  
  # Summary
  echo
  echo "=================================================="
  log_info "VISIBILITY CHANGE SUMMARY"
  echo "=================================================="
  log_success "Successfully made private: $success_count/$total_repos repositories"
  
  if [[ ${#failed_repos[@]} -gt 0 ]]; then
    log_warning "Failed repositories:"
    for failed_repo in "${failed_repos[@]}"; do
      echo "  - $failed_repo"
    done
  fi
  
  echo
  log_success "Repository visibility change process completed!"
}

# Function to show current visibility status
show_visibility_status() {
  echo "🔍 Current Repository Visibility Status"
  echo "====================================="
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
    
    local visibility=$(get_repo_visibility "$REPO")
    
    if [[ "$visibility" == "public" ]]; then
      echo "  🌐 $REPO ($REPO_TYPE): Public"
    elif [[ "$visibility" == "private" ]]; then
      echo "  🔒 $REPO ($REPO_TYPE): Private"
    else
      echo "  ❓ $REPO ($REPO_TYPE): Unknown visibility ($visibility)"
    fi
  done
  
  echo
}

# Function to show help
show_help() {
  echo "Repository Visibility Management Script"
  echo "======================================"
  echo
  echo "This script changes the visibility (public/private) of CloudInsight repositories."
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
  echo "  --status       Show current visibility status of all repositories"
  echo "  --public       Make all repositories public"
  echo "  --private      Make all repositories private"
  echo "  --repo REPO    Operate on a specific repository only (use with --public or --private)"
  echo
  echo "Examples:"
  echo "  $0 --status                    Show visibility status for all repositories"
  echo "  $0 --public                    Make all repositories public"
  echo "  $0 --private                   Make all repositories private"
  echo "  $0 --public --repo cloudinsight-frontend-rw    Make a specific repository public"
  echo "  $0 --private --repo cloudinsight-frontend-rw   Make a specific repository private"
  echo
  echo "Prerequisites:"
  echo "  - GitHub CLI (gh) must be installed and authenticated"
  echo "  - You must have admin access to the repositories in $ORG organization"
  echo
  echo "Note:"
  echo "  Making repositories public will expose all code to everyone on the internet."
  echo "  Be careful when changing visibility, especially when making repositories public."
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
      "--public")
        ACTION="public"
        shift
        ;;
      "--private")
        ACTION="private"
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
      show_visibility_status
      ;;
    "public")
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
          echo "🌐 Making Repository Public: $SPECIFIC_REPO ($REPO_TYPE)"
          echo "=============================================="
          echo
          
          if repo_exists "$SPECIFIC_REPO"; then
            # Ask for confirmation before making public
            log_warning "You are about to make $SPECIFIC_REPO repository PUBLIC."
            log_warning "This will expose all code to everyone on the internet."
            echo
            read -p "Are you sure you want to continue? (y/N): " REPLY
            
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
              log_warning "Operation cancelled by user"
              exit 0
            fi
            
            make_repo_public "$SPECIFIC_REPO"
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
        echo "🌐 Making All Repositories Public"
        echo "==============================="
        echo
        
        log_info "This script will make the following repositories public:"
        for REPO_CONFIG in "${REPOS[@]}"; do
          REPO=$(get_repo_name "$REPO_CONFIG")
          REPO_TYPE=$(get_repo_type "$REPO_CONFIG")
          echo "  - $REPO ($REPO_TYPE)"
        done
        echo
        log_warning "WARNING: Making repositories public will expose all code to everyone on the internet."
        
        echo
        read -p "Are you sure you want to continue? (y/N): " REPLY
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          log_warning "Operation cancelled by user"
          exit 0
        fi
        
        make_all_repos_public
      fi
      ;;
    "private")
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
          echo "🔒 Making Repository Private: $SPECIFIC_REPO ($REPO_TYPE)"
          echo "=============================================="
          echo
          
          if repo_exists "$SPECIFIC_REPO"; then
            make_repo_private "$SPECIFIC_REPO"
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
        echo "🔒 Making All Repositories Private"
        echo "==============================="
        echo
        
        log_info "This script will make the following repositories private:"
        for REPO_CONFIG in "${REPOS[@]}"; do
          REPO=$(get_repo_name "$REPO_CONFIG")
          REPO_TYPE=$(get_repo_type "$REPO_CONFIG")
          echo "  - $REPO ($REPO_TYPE)"
        done
        echo
        
        read -p "Do you want to continue? (y/N): " REPLY
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          log_warning "Operation cancelled by user"
          exit 0
        fi
        
        make_all_repos_private
      fi
      ;;
    *)
      log_error "No action specified. Use --status, --public, or --private"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
}

# Run the script
main "$@"
