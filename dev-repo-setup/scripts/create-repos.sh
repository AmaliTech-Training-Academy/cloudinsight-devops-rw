#!/bin/bash

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
REPOS=(
  "cloudinsight-api-gateway-rw:backend"
  "cloudinsight-service-discovery-rw:backend"
  "cloudinsight-config-server-rw:backend"
  "cloudinsight-config-repo-rw:backend"
  # "cloudinsight-user-service-rw:backend"
  # "cloudinsight-cost-service-rw:backend"
  # "cloudinsight-metric-service-rw:backend"
  # "cloudinsight-anomaly-service-rw:backend"
  # "cloudinsight-forecast-service-rw:backend"
  # "cloudinsight-notification-service-rw:backend"
#   "cloudinsight-backend-rw:backend"
    # "cloudinsight-frontend-rw:frontend"
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

  if ! command -v git &> /dev/null; then
    log_error "Git is not installed. Please install it first."
    exit 1
  fi

  log_success "GitHub CLI is installed and authenticated"
  log_success "Git is available"
}

# Function to get repository type
get_repo_type() {
  local REPO_CONFIG=$1
  echo "${REPO_CONFIG##*:}"
}

# Function to get repository name
get_repo_name() {
  local REPO_CONFIG=$1
  echo "${REPO_CONFIG%%:*}"
}

# Function to check if repository is an infrastructure repository
is_infrastructure_repo() {
  local REPO=$1
  case "$REPO" in
    "cloudinsight-api-gateway-rw"|"cloudinsight-service-discovery-rw"|"cloudinsight-config-server-rw"|"cloudinsight-config-repo-rw")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Function to check if user is already a collaborator
is_collaborator() {
  local REPO=$1
  local USERNAME=$2
  
  # First, try to check directly if the user is a collaborator (more reliable)
  if gh api "repos/$ORG/$REPO/collaborators/$USERNAME" &> /dev/null; then
    return 0  # User is definitely a collaborator
  fi
  
  # Fallback: get full list of collaborators and check if username is in the list (case-insensitive)
  if gh api "repos/$ORG/$REPO/collaborators" --jq '.[].login' 2>/dev/null | grep -qi "^${USERNAME}$"; then
    return 0  # User is in the list of collaborators
  fi
  
  # Final check: see if the user has permission through organization roles
  # This checks if they have at least read access
  local PERMISSION=$(gh api "repos/$ORG/$REPO/collaborators/$USERNAME/permission" --jq '.permission' 2>/dev/null)
  if [[ -n "$PERMISSION" && "$PERMISSION" != "none" ]]; then
    return 0  # User has some form of access
  fi
  
  return 1  # User is not a collaborator
}

# Function to remove branch protection rules
remove_branch_protection() {
  local REPO=$1
  local BRANCH=$2
  
  # Remove branch protection if it exists
  if gh api "repos/$ORG/$REPO/branches/$BRANCH/protection" &> /dev/null; then
    if gh api --method DELETE "repos/$ORG/$REPO/branches/$BRANCH/protection" &> /dev/null; then
      log_info "  ✓ Removed branch protection for $BRANCH"
    else
      log_warning "  ⚠️ Failed to remove branch protection for $BRANCH"
    fi
  fi
}

# Function to check if invitation is valid and recreate if needed
check_and_fix_invitation() {
  local REPO=$1
  local USERNAME=$2
  local PERMISSION=$3
  
  # Skip invitation for bikaze (admin/owner)
  if [[ "$USERNAME" == "bikaze" ]]; then
    log_info "  ✓ @$USERNAME is the repository admin/owner (skipping invitation)"
    return 0
  fi
  
  # Check if user exists first
  if ! gh api "users/$USERNAME" &> /dev/null; then
    log_error "  ❌ Could not invite @$USERNAME - username does not exist"
    return 1
  fi
  
  # Check if user is an org member first - this is just for logging
  local IS_ORG_MEMBER=false
  if gh api "orgs/$ORG/members/$USERNAME" &> /dev/null; then
    IS_ORG_MEMBER=true
  fi
  
  # Check if user is already a collaborator with proper permissions
  local CURRENT_PERMISSION=$(gh api "repos/$ORG/$REPO/collaborators/$USERNAME/permission" --jq '.permission' 2>/dev/null || echo "none")
  
  if [[ "$CURRENT_PERMISSION" != "none" ]]; then
    if [[ "$CURRENT_PERMISSION" == "$PERMISSION" ]] || [[ "$CURRENT_PERMISSION" == "admin" ]]; then
      log_info "  ✓ @$USERNAME already has $CURRENT_PERMISSION access (sufficient)"
      return 0
    else
      log_info "  → @$USERNAME has $CURRENT_PERMISSION access, updating to $PERMISSION..."
    fi
  fi
  
  # Try a direct invitation/permission update regardless of current status
  log_info "  → Inviting/updating @$USERNAME with $PERMISSION permissions..."
  
  # Use the REST API directly for more reliable operation
  local INVITE_RESULT=$(gh api \
    --method PUT \
    "repos/$ORG/$REPO/collaborators/$USERNAME" \
    -f permission="$PERMISSION" \
    --silent 2>/dev/null || echo "ERROR")
  
  # Check if invitation was successful
  if [[ "$INVITE_RESULT" == "ERROR" ]]; then
    # Try CLI command as backup method
    if gh repo add-collaborator "$ORG/$REPO" --username "$USERNAME" --permission "$PERMISSION" 2>/dev/null; then
      log_success "  ✓ Successfully invited @$USERNAME ($PERMISSION access) - backup method"
      return 0
    fi
    
    # Try alternative CLI method with different syntax
    if gh api --method PUT "repos/$ORG/$REPO/collaborators/$USERNAME" --field permission="$PERMISSION" 2>/dev/null; then
      log_success "  ✓ Successfully invited @$USERNAME ($PERMISSION access) - alternative method"
      return 0
    fi
    
    # Final attempt with basic invitation (no specific permission)
    if gh api --method PUT "repos/$ORG/$REPO/collaborators/$USERNAME" 2>/dev/null; then
      log_success "  ✓ Successfully invited @$USERNAME (basic access) - fallback method"
      return 0
    fi
    
    # Check if user now has access despite the error
    local FINAL_PERMISSION=$(gh api "repos/$ORG/$REPO/collaborators/$USERNAME/permission" --jq '.permission' 2>/dev/null || echo "none")
    if [[ "$FINAL_PERMISSION" != "none" ]]; then
      log_success "  ✓ @$USERNAME now has $FINAL_PERMISSION access"
      return 0
    fi
    
    # Check for pending invitation
    local INVITATION_ID=$(gh api "repos/$ORG/$REPO/invitations" --jq ".[] | select(.invitee.login == \"$USERNAME\") | .id" 2>/dev/null)
    if [[ -n "$INVITATION_ID" ]]; then
      log_success "  ✓ @$USERNAME has a pending invitation"
      return 0
    fi
    
    # All methods failed
    if [[ "$IS_ORG_MEMBER" == "true" ]]; then
      log_warning "  ⚠️ Failed to invite @$USERNAME (org member) - may need manual intervention"
    else  
      log_warning "  ⚠️ Failed to invite @$USERNAME - manual invitation may be needed"
    fi
    return 1
  else
    # Successful invitation
    if [[ "$IS_ORG_MEMBER" == "true" ]]; then
      log_success "  ✓ Successfully invited @$USERNAME ($PERMISSION access) - org member"
    else
      log_success "  ✓ Successfully invited @$USERNAME ($PERMISSION access)"
    fi
    return 0
  fi
}

# Function to invite collaborators to repository
invite_collaborators() {
  local REPO=$1
  local REPO_TYPE=$2
  
  log_info "Inviting collaborators to $REPO ($REPO_TYPE repository)"
  
  # Check if this is an infrastructure repository
  if is_infrastructure_repo "$REPO"; then
    log_info "  → Infrastructure repository: Inviting only Eric and Oliv..."
    
    # Track failures for summary report
    local FAILED_INVITATIONS=()
    local SUCCESS_COUNT=0
    local TOTAL_INVITES=0
    
    # Function to process a single invitation
    process_invitation() {
      local username=$1
      local permission=$2
      local role=$3
      ((TOTAL_INVITES++))
      
      if check_and_fix_invitation "$REPO" "$username" "$permission"; then
        ((SUCCESS_COUNT++))
      else
        FAILED_INVITATIONS+=("$username")
      fi
    }
    
    # Only invite Eric and Oliv for infrastructure repos
    process_invitation "ericndungutse" "push" "backend developer"
    process_invitation "ingabireol" "push" "backend developer"
    
    # Print summary of invitations
    if [[ ${#FAILED_INVITATIONS[@]} -gt 0 ]]; then
      log_info "Invitation summary: $SUCCESS_COUNT/$TOTAL_INVITES successful"
      log_warning "The following invitations may need manual attention:"
      for failed in "${FAILED_INVITATIONS[@]}"; do
        echo "  - @$failed"
      done
      return 1
    else
      log_success "All invitations ($SUCCESS_COUNT) processed successfully"
      return 0
    fi
  fi
  
  # Regular repository invitation logic (for non-infrastructure repos)
  # Define collaborators based on repo type
  local FRONTEND_COLLABORATORS=("princoo" "muodilo")
  local BACKEND_COLLABORATORS=("ericndungutse" "ingabireol")
  
  # Define codeowners based on repo type (without @ prefix for GitHub CLI)
  local FRONTEND_CODEOWNERS=(
    "bencyubahiro77"
    "aimerukundo"
    "tharcissie"
    "bikaze"  # bikaze is in both for .github/ ownership
  )
  
  local BACKEND_CODEOWNERS=(
    "nkbtemmy2"
    "bumlev"
    "bikaze"  # bikaze is in both for .github/ ownership
  )
  
  # Add staging and production codeowners (they have access to all repos)
  local UNIVERSAL_CODEOWNERS=(
    "sntakirutimana72"  # staging branch owner
    "bikaze"  # production branch owner and .github/ owner
  )
  
  # Track failures for summary report
  local FAILED_INVITATIONS=()
  local SUCCESS_COUNT=0
  local TOTAL_INVITES=0
  
  # Function to process a single invitation
  process_invitation() {
    local username=$1
    local permission=$2
    local role=$3  # Role description for logging
    ((TOTAL_INVITES++))
    
    if check_and_fix_invitation "$REPO" "$username" "$permission"; then
      ((SUCCESS_COUNT++))
    else
      FAILED_INVITATIONS+=("$username")
    fi
  }
  
  # Invite type-specific collaborators with write permission
  if [[ "$REPO_TYPE" == "frontend" ]]; then
    log_info "  → Inviting frontend-specific collaborators..."
    for collaborator in "${FRONTEND_COLLABORATORS[@]}"; do
      process_invitation "$collaborator" "push" "frontend collaborator"
    done
  elif [[ "$REPO_TYPE" == "backend" ]]; then
    log_info "  → Inviting backend-specific collaborators..."
    for collaborator in "${BACKEND_COLLABORATORS[@]}"; do
      process_invitation "$collaborator" "push" "backend collaborator"
    done
  fi
  
  # Invite repo-specific codeowners with write permission
  local REPO_CODEOWNERS=()
  
  if [[ "$REPO_TYPE" == "frontend" ]]; then
    REPO_CODEOWNERS=("${FRONTEND_CODEOWNERS[@]}")
    log_info "  → Inviting frontend codeowners..."
  elif [[ "$REPO_TYPE" == "backend" ]]; then
    REPO_CODEOWNERS=("${BACKEND_CODEOWNERS[@]}")
    log_info "  → Inviting backend codeowners..."
  fi
  
  # Add universal codeowners to the list
  for universal_owner in "${UNIVERSAL_CODEOWNERS[@]}"; do
    # Check if not already in the list to avoid duplicates
    local already_added=false
    for existing_owner in "${REPO_CODEOWNERS[@]}"; do
      if [[ "$existing_owner" == "$universal_owner" ]]; then
        already_added=true
        break
      fi
    done
    if [[ "$already_added" == false ]]; then
      REPO_CODEOWNERS+=("$universal_owner")
    fi
  done
  
  # Invite the determined codeowners
  for codeowner in "${REPO_CODEOWNERS[@]}"; do
    process_invitation "$codeowner" "push" "codeowner"
  done
  
  # Add universal codeowners invitation
  log_info "  → Inviting universal codeowners..."
  for universal_owner in "${UNIVERSAL_CODEOWNERS[@]}"; do
    # Only invite if not already processed above
    local already_processed=false
    for processed_owner in "${REPO_CODEOWNERS[@]}"; do
      if [[ "$processed_owner" == "$universal_owner" ]]; then
        already_processed=true
        break
      fi
    done
    if [[ "$already_processed" == false ]]; then
      process_invitation "$universal_owner" "push" "universal codeowner"
    fi
  done
  
  # Print summary of invitations
  if [[ ${#FAILED_INVITATIONS[@]} -gt 0 ]]; then
    log_info "Invitation summary: $SUCCESS_COUNT/$TOTAL_INVITES successful"
    log_warning "The following invitations may need manual attention:"
    for failed in "${FAILED_INVITATIONS[@]}"; do
      echo "  - @$failed"
    done
    return 1
  else
    log_success "All invitations ($SUCCESS_COUNT) processed successfully"
    return 0
  fi
}

# Function to create branches with strategic CODEOWNERS setup
setup_branches_and_codeowners() {
  local REPO=$1
  local REPO_TYPE=$2
  local TEMP_DIR="/tmp/repo_setup_$$"
  
  # Get the original script directory before changing to temp directory
  local ORIGINAL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  
  # Check if this is an infrastructure repository
  if is_infrastructure_repo "$REPO"; then
    log_info "Setting up infrastructure repository: $REPO (simple setup with README only)"
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Clone the repository
    if ! git clone "https://github.com/$ORG/$REPO.git" "$TEMP_DIR" &> /dev/null; then
      log_error "Failed to clone repository $REPO for setup"
      rm -rf "$TEMP_DIR"
      return 1
    fi
    
    cd "$TEMP_DIR"
    
    # Configure git
    git config user.email "clmntmugisha@gmail.com"
    git config user.name "bikaze"
    
    # Get current branch name (should be main for new repos)
    local INITIAL_BRANCH=$(git branch --show-current)
    
    # Create/customize README.md
    echo "# $REPO" > README.md
    echo "" >> README.md
    echo "This is the $REPO infrastructure repository." >> README.md
    echo "" >> README.md
    echo "## Description" >> README.md
    echo "Infrastructure component for the CloudInsight platform." >> README.md
    log_info "  ✓ Created infrastructure README.md"
    
    # Commit the README
    git add README.md
    if git diff --staged --quiet; then
      log_info "  ℹ️ No README changes to commit"
    else
      git commit -m "Add infrastructure repository README" &> /dev/null
      log_info "  ✓ Committed README.md"
    fi
    
    # Keep main as default branch for infrastructure repos
    if [[ "$INITIAL_BRANCH" == "main" ]]; then
      git push -u origin main
      log_info "  ✓ Pushed changes to main branch"
    else
      # If for some reason the initial branch isn't main, rename it to main
      git branch -m "$INITIAL_BRANCH" main
      git push -u origin main
      log_info "  ✓ Renamed $INITIAL_BRANCH to main and pushed"
    fi

    # Ensure main is the default branch
    gh repo edit "$ORG/$REPO" --default-branch main &> /dev/null || true
    log_info "  ✓ Set main as default branch"    log_info "  ✓ Infrastructure repository setup complete"
    
    # Cleanup
    cd - &> /dev/null
    rm -rf "$TEMP_DIR"
    return 0
  fi
  
  # Regular repository setup with CODEOWNERS
  log_info "Setting up branches with strategic CODEOWNERS approach for $REPO"
  
  # Create temporary directory
  mkdir -p "$TEMP_DIR"
  
  # Clone the repository
  if ! git clone "https://github.com/$ORG/$REPO.git" "$TEMP_DIR" &> /dev/null; then
    log_error "Failed to clone repository $REPO for branch setup"
    rm -rf "$TEMP_DIR"
    return 1
  fi
  
  cd "$TEMP_DIR"
  
  # Configure git
  git config user.email "clmntmugisha@gmail.com"
  git config user.name "bikaze"
  
  # Use the original script directory to build paths
  local TEMPLATE_DIR="$ORIGINAL_SCRIPT_DIR/../templates/$REPO_TYPE"
  local CODEOWNERS_DIR="$ORIGINAL_SCRIPT_DIR/../branch-codeowners"
  
  # Verify CODEOWNERS files exist
  if [[ ! -f "$CODEOWNERS_DIR/CODEOWNERS.staging" ]]; then
    log_error "❌ Missing staging CODEOWNERS file: $CODEOWNERS_DIR/CODEOWNERS.staging"
    return 1
  fi
  
  if [[ ! -f "$CODEOWNERS_DIR/CODEOWNERS.production" ]]; then
    log_error "❌ Missing production CODEOWNERS file: $CODEOWNERS_DIR/CODEOWNERS.production"
    return 1
  fi
  
  # Remove branch protection rules for all branches
  for branch in "main" "development" "staging" "production"; do
    remove_branch_protection "$REPO" "$branch"
  done
  
  # Get current branch name (should be main for new repos)
  local INITIAL_BRANCH=$(git branch --show-current)
  
  # Apply proper template files for this repo type
  log_info "  → Applying $REPO_TYPE template files to $INITIAL_BRANCH branch..."
  
  # Copy .github directory from template
  if [[ -d "$TEMPLATE_DIR/.github" ]]; then
    mkdir -p .github
    cp -r "$TEMPLATE_DIR/.github/." ./.github/
    log_info "  ✓ Copied .github directory from template"
  fi
  
  # Create/customize README.md if it doesn't exist or is default
  if [[ ! -f "README.md" ]] || grep -q "# $REPO" README.md 2>/dev/null; then
    if [[ -f "$TEMPLATE_DIR/README.md" ]]; then
      sed "s/{{REPO_NAME}}/$REPO/g" "$TEMPLATE_DIR/README.md" > ./README.md
      log_info "  ✓ Customized README.md from template"
    else
      echo "# $REPO" > README.md
      echo "This is the $REPO repository ($REPO_TYPE)." >> README.md
      log_info "  ✓ Created basic README.md"
    fi
  fi
  
  # Commit template files to establish base
  git add .
  if git diff --staged --quiet; then
    log_info "  ℹ️ No template changes to commit"
  else
    git commit -m "Apply $REPO_TYPE template with .github workflows and initial setup" &> /dev/null
    log_info "  ✓ Committed template files"
  fi
  
  # PROPERLY rename main branch to development (not create new branch)
  log_info "  → Current branch is '$INITIAL_BRANCH', checking if rename is needed..."
  
  if [[ "$INITIAL_BRANCH" == "main" ]]; then
    log_info "  → Renaming main branch to development..."
    
    # Step 1: Rename local branch from main to development
    git branch -m main development
    
    # Step 2: Push the development branch with upstream tracking
    git push -u origin development
    
    # Step 3: Set development as the new default branch on GitHub
    gh repo edit "$ORG/$REPO" --default-branch development
    
    # Step 4: Delete the old main branch from remote
    git push origin --delete main
    
    log_info "  ✓ Successfully renamed main → development and updated default branch"
  elif [[ "$INITIAL_BRANCH" == "development" ]]; then
    # Already on development, just push it
    git push -u origin development
    log_info "  ✓ Already on development branch, pushed to remote"
  else
    # On some other branch, create development from this branch
    log_info "  → On branch '$INITIAL_BRANCH', creating development branch..."
    git checkout -b development
    git push -u origin development
    
    # Set development as default branch
    gh repo edit "$ORG/$REPO" --default-branch development
    log_info "  ✓ Created and pushed development branch, set as default"
  fi
  
  # PHASE 1: Setup development branch with development-specific CODEOWNERS
  mkdir -p .github
  
  if [[ "$REPO_TYPE" == "frontend" ]]; then
    cat > .github/CODEOWNERS << 'EOF'
# Development branch code owners - Frontend
# .github folder managed by bikaze
/.github/ @bikaze

# Everything else managed by frontend team
* @bencyubahiro77 @aimerukundo @tharcissie
EOF
  else
    cat > .github/CODEOWNERS << 'EOF'
# Development branch code owners - Backend  
# .github folder managed by bikaze
/.github/ @bikaze

# Everything else managed by backend team
* @nkbtemmy2 @bumlev
EOF
  fi
  
  git add .github/CODEOWNERS
  git commit -m "Add development-specific CODEOWNERS" &> /dev/null || true
  git push origin development &> /dev/null
  log_info "  ✓ Applied development-specific CODEOWNERS"
  
  # PHASE 2: Create staging branch from development and apply staging CODEOWNERS
  git checkout -b staging development &> /dev/null
  
  # Replace CODEOWNERS with staging-specific version
  cp "$CODEOWNERS_DIR/CODEOWNERS.staging" .github/CODEOWNERS
  
  git add .github/CODEOWNERS
  git commit -m "Add staging-specific CODEOWNERS" &> /dev/null || true
  git push -u origin staging &> /dev/null
  log_info "  ✓ Created staging branch from development with staging-specific CODEOWNERS"
  
  # PHASE 3: Create production branch from development and apply production CODEOWNERS
  git checkout development &> /dev/null
  git checkout -b production development &> /dev/null
  
  # Replace CODEOWNERS with production-specific version
  cp "$CODEOWNERS_DIR/CODEOWNERS.production" .github/CODEOWNERS
  
  git add .github/CODEOWNERS
  git commit -m "Add production-specific CODEOWNERS" &> /dev/null || true
  git push -u origin production &> /dev/null
  log_info "  ✓ Created production branch from development with production-specific CODEOWNERS"
  
  # Return to development branch
  git checkout development &> /dev/null
  
  # Set development as default branch
  gh repo edit "$ORG/$REPO" --default-branch development &> /dev/null || true
  log_info "  ✓ Set development as default branch"
  
  log_info "  ✓ Branch-specific CODEOWNERS setup complete: Each branch has tailored access control"
  
  # Cleanup
  cd - &> /dev/null
  rm -rf "$TEMP_DIR"
  
  return 0
}

# Function to apply template files to repository
apply_template() {
  local REPO=$1
  local REPO_TYPE=$2
  local TEMP_DIR="/tmp/repo_template_$$"
  
  log_info "Applying $REPO_TYPE template to $REPO"
  
  # Create temporary directory
  mkdir -p "$TEMP_DIR"
  
  # Clone the repository to apply templates
  if ! git clone "https://github.com/$ORG/$REPO.git" "$TEMP_DIR" &> /dev/null; then
    log_error "Failed to clone repository $REPO for template application"
    rm -rf "$TEMP_DIR"
    return 1
  fi
  
  cd "$TEMP_DIR"
  
  # Copy template files
  local TEMPLATE_DIR="/home/bkz/amalitech/capstone-proj/cloudinsight-devops-rw/templates/$REPO_TYPE"
  
  if [[ ! -d "$TEMPLATE_DIR" ]]; then
    log_error "Template directory for $REPO_TYPE not found: $TEMPLATE_DIR"
    cd - &> /dev/null
    rm -rf "$TEMP_DIR"
    return 1
  fi
  
  # Copy .github directory
  if [[ -d "$TEMPLATE_DIR/.github" ]]; then
    mkdir -p .github
    cp -r "$TEMPLATE_DIR/.github/." ./.github/
    log_info "  ✓ Copied .github directory"
  fi
  
  # Copy and customize README.md
  if [[ -f "$TEMPLATE_DIR/README.md" ]]; then
    sed "s/{{REPO_NAME}}/$REPO/g" "$TEMPLATE_DIR/README.md" > ./README.md
    log_info "  ✓ Customized README.md"
  fi
  
  # Stage and commit changes
  git add .
  git config user.email "clmntmugisha@gmail.com"
  git config user.name "bikaze"
  
  if git diff --staged --quiet; then
    log_info "  ℹ️ No template changes to commit"
  else
    # First determine if we're on main branch
    local CURRENT_BRANCH=$(git branch --show-current)
    
    if [[ "$CURRENT_BRANCH" == "main" ]]; then
      # If on main, rename to development before pushing
      git commit -m "Apply $REPO_TYPE template with .github workflows and initial setup"
      
      # Rename main to development
      git branch -m main development
      git push -u origin development
      git push origin --delete main &> /dev/null || true
      
      # Set as default branch
      gh repo edit "$ORG/$REPO" --default-branch development &> /dev/null
      log_success "  ✓ Template applied and pushed (with main → development rename)"
    else
      # Otherwise just commit and push to current branch
      git commit -m "Apply $REPO_TYPE template with .github workflows and initial setup"
      git push origin "$CURRENT_BRANCH" &> /dev/null
      log_success "  ✓ Template applied and pushed to $CURRENT_BRANCH branch"
    fi
  fi
  
  # Cleanup
  cd - &> /dev/null
  rm -rf "$TEMP_DIR"
  
  return 0
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

# Function to update existing repository with full configuration
update_existing_repository() {
  local REPO=$1
  local REPO_TYPE=$2
  
  log_info "Updating existing repository: $REPO with full configuration"
  
  # Setup branches with proper main → development rename 
  # (template files are applied within the branch setup function)
  if setup_branches_and_codeowners "$REPO" "$REPO_TYPE"; then
    # Invite collaborators and codeowners
    if invite_collaborators "$REPO" "$REPO_TYPE"; then
      log_success "✓ Repository $REPO updated with branches, CODEOWNERS, and collaborators successfully"
      return 0
    else
      log_warning "✓ Repository $REPO updated but some collaborator invitations failed"
      return 0
    fi
  else
    log_warning "✓ Repository $REPO exists but branch setup failed"
    return 0
  fi
}

# Function to create a repository
create_repository() {
  local REPO=$1
  local REPO_TYPE=$2
  local DESCRIPTION="CloudInsight project repository - $REPO ($REPO_TYPE)"
  
  log_info "Creating $REPO_TYPE repository: $REPO"
  
  # Create the repository (public, no gitignore, no license)
  if gh repo create "$ORG/$REPO" \
    --description "$DESCRIPTION" \
    --public \
    --add-readme; then
    
    # Wait a moment for repository to be fully created
    sleep 3
    
    log_info "Successfully created repository $REPO, now configuring branches and templates"
    
    # Set up branches with proper main → development rename
    if setup_branches_and_codeowners "$REPO" "$REPO_TYPE"; then
      # Invite collaborators and codeowners
      if invite_collaborators "$REPO" "$REPO_TYPE"; then
        log_success "✓ Repository $REPO created with branches, CODEOWNERS, and collaborators successfully"
        return 0
      else
        log_warning "✓ Repository $REPO created and configured but some collaborator invitations failed"
        return 0
      fi
    else
      log_warning "✓ Repository $REPO created but branch setup failed"
      return 0
    fi
  else
    log_error "✗ Failed to create repository $REPO"
    return 1
  fi
}

# Function to create all repositories
create_all_repositories() {
  log_info "Starting repository creation process..."
  echo
  
  local TOTAL_REPOS=${#REPOS[@]}
  local CURRENT_REPO=0
  local SUCCESS_COUNT=0
  local FAILED_REPOS=()
  local EXISTING_REPOS=()
  
  # Process each repository
  for REPO_CONFIG in "${REPOS[@]}"; do
    CURRENT_REPO=$((CURRENT_REPO + 1))
    
    # Extract repo name and type
    REPO=$(get_repo_name "$REPO_CONFIG")
    REPO_TYPE=$(get_repo_type "$REPO_CONFIG")
    
    echo
    log_info "Processing repository $CURRENT_REPO/$TOTAL_REPOS: $REPO ($REPO_TYPE)"
    
    # Check if repository already exists
    if repo_exists "$REPO"; then
      log_warning "Repository $REPO already exists - applying full configuration"
      if update_existing_repository "$REPO" "$REPO_TYPE"; then
        log_success "✓ Existing repository $REPO updated successfully"
      else
        log_warning "⚠️ Some updates for existing repository $REPO failed"
      fi
      EXISTING_REPOS+=("$REPO")
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
      continue
    fi
    
    # Create the repository
    if create_repository "$REPO" "$REPO_TYPE"; then
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
      FAILED_REPOS+=("$REPO")
    fi
  done
  
  # Summary
  echo
  echo "=================================="
  log_info "REPOSITORY CREATION SUMMARY"
  echo "=================================="
  log_success "Successfully processed: $SUCCESS_COUNT/$TOTAL_REPOS repositories"
  
  if [[ ${#EXISTING_REPOS[@]} -gt 0 ]]; then
    echo
    log_info "Repositories that already existed (collaborators updated):"
    for EXISTING_REPO in "${EXISTING_REPOS[@]}"; do
      echo "  - $ORG/$EXISTING_REPO"
    done
  fi
  
  if [[ ${#FAILED_REPOS[@]} -gt 0 ]]; then
    echo
    log_warning "Failed to create repositories:"
    for FAILED_REPO in "${FAILED_REPOS[@]}"; do
      echo "  - $ORG/$FAILED_REPO"
    done
    echo
    log_error "Some repositories failed to be created. Please check the errors above."
    exit 1
  fi
  
  echo
  log_success "All repositories have been processed successfully!"
  echo
  log_info "You can view the repositories at:"
  for REPO_CONFIG in "${REPOS[@]}"; do
    REPO=$(get_repo_name "$REPO_CONFIG")
    echo "  https://github.com/$ORG/$REPO"
  done
}

# Function to show help
show_help() {
  echo "Repository Creation Script"
  echo "=========================="
  echo
  echo "This script creates the following repositories in the $ORG organization:"
  for REPO_CONFIG in "${REPOS[@]}"; do
    REPO=$(get_repo_name "$REPO_CONFIG")
    REPO_TYPE=$(get_repo_type "$REPO_CONFIG")
    echo "  - $REPO ($REPO_TYPE)"
  done
  echo
  echo "Features:"
  echo "  - Checks if repositories already exist before creating"
  echo "  - For existing repositories: applies full configuration (branches, CODEOWNERS, templates)"
  echo "  - Removes branch protection rules for proper setup"
  echo "  - Validates invitations and recreates invalid ones"
  echo "  - Creates repositories with appropriate templates (frontend/backend)"
  echo "  - Creates three branches: development, staging, production"
  echo "  - Applies tailored CODEOWNERS files per branch:"
  echo "    • Development branch: Team-specific code review requirements"
  echo "    • Staging branch: Staging environment gatekeepers"
  echo "    • Production branch: Production-only approvers"
  echo "  - Active GitHub CODEOWNERS enforcement per branch"
  echo "  - Renames main → development (efficient branch management)"
  echo "  - Invites collaborators and codeowners with appropriate permissions"
  echo "  - Applies .github/workflows/ci.yml for CI pipeline"
  echo "  - Customizes README.md with repository name"
  echo "  - Sets development as default branch"
  echo "  - Provides detailed progress and summary information"
  echo
  echo "Usage:"
  echo "  $0 [--help]"
  echo
  echo "Options:"
  echo "  --help    Show this help message"
  echo
  echo "Prerequisites:"
  echo "  - GitHub CLI (gh) must be installed and authenticated"
  echo "  - Git must be installed"
  echo "  - You must have admin access to create repositories in the $ORG organization"
  echo
  echo "Authentication:"
  echo "  If not already authenticated, run: gh auth login"
  echo
}

# Main function
main() {
  # Check for help flag
  if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
  fi
  
  echo "🏗️  Repository Creation Script"
  echo "=============================="
  echo
  
  # Check prerequisites
  log_info "Checking prerequisites..."
  check_gh_cli
  
  echo
  log_info "This script will create the following repositories in the $ORG organization:"
  for REPO_CONFIG in "${REPOS[@]}"; do
    REPO=$(get_repo_name "$REPO_CONFIG")
    REPO_TYPE=$(get_repo_type "$REPO_CONFIG")
    echo "  - $REPO ($REPO_TYPE)"
  done
  
  echo
  log_info "Each repository will be created with:"
  echo "  - Public visibility"
  echo "  - Three branches: development (default), staging, production"
  echo "  - Branch-specific CODEOWNERS setup (tailored access control per branch):"
  echo "    • Development: Frontend/Backend teams + @bikaze for .github/"
  echo "    • Staging: @sntakirutimana72 + @bikaze for .github/"
  echo "    • Production: @bikaze for everything"
  echo "  - Smart collaborator management:"
  echo "    • Checks existing collaborators before inviting"
  echo "    • Frontend repos: @princoo, @muodilo (write access)"
  echo "    • Backend repos: @ericndungutse, @ingabireol (write access)"
  echo "  - Active CODEOWNERS enforcement:"
  echo "    • Each branch has its own CODEOWNERS file"
  echo "    • Branch-specific access control is enforced by GitHub"
  echo "    • Different approval requirements per branch environment"
  echo "    • Renames main → development (efficient branch management)"
  echo "  - Customized README.md with repository name"
  echo "  - .github/workflows/ci.yml (CI pipeline)"
  echo
  log_info "For existing repositories:"
  echo "  - Applies full configuration (branches, CODEOWNERS, templates)"
  echo "  - Removes branch protection rules"
  echo "  - Validates and recreates invalid invitations"
  echo "  - Ensures proper branch structure and default branch"
  
  echo
  read -p "Do you want to continue with repository creation? (y/N): " REPLY
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "Operation cancelled by user"
    exit 0
  fi
  
  # Start the creation process
  create_all_repositories
}

# Run the script
main "$@"
