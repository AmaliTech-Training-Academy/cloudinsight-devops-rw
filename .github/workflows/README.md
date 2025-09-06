# Enhanced CI/CD Workflows

This directory contains enhanced GitHub Actions workflows that implement:

## Features

- **AWS Secrets Manager Integration**: Automated deployment of encrypted environment variables
- **ECR Image Publishing**: Docker image building and pushing to Amazon ECR
- **Semantic Versioning**: Automatic version tagging based on conventional commits
- **GitHub Releases**: Automated release creation with proper metadata
- **Branch Protection**: Deploy operations only execute on main branch

## Workflows

### Backend CI/CD (`backend/ci.yml`)
- Tests Java/Maven projects
- Deploys to backend ECR repository
- Uses semantic versioning (e.g., `v1.2.3`)

### Frontend CI/CD (`frontend/ci.yml`)
- Tests Node.js/pnpm projects
- Deploys to frontend ECR repository
- Uses prefixed semantic versioning (e.g., `frontend-v1.2.3`)

## Required GitHub Secrets

Add these secrets to your GitHub repository settings:

```bash
# AWS Configuration (Required)
AWS_REGION                              # e.g., "us-west-2"
AWS_ACCOUNT_ID                          # e.g., "123456789012"
AWS_ACCESS_KEY_ID                       # AWS access key with ECR and Secrets Manager permissions
AWS_SECRET_ACCESS_KEY                   # Corresponding secret key

# Encryption Key (Required)
TEAM_PRIVATE_KEY                        # RSA private key for decrypting environment variables

# Secrets Manager Names (Required)
AWS_SECRETS_MANAGER_SECRET_NAME_BACKEND   # e.g., "myapp/backend/env-vars"
AWS_SECRETS_MANAGER_SECRET_NAME_FRONTEND  # e.g., "myapp/frontend/env-vars"

# ECR Repository Names (Required)
ECR_REPOSITORY_BACKEND                   # e.g., "myapp-backend"
ECR_REPOSITORY_FRONTEND                  # e.g., "myapp-frontend"
```

## Conventional Commits

The workflows use conventional commits for semantic versioning:

```bash
# Valid commits that trigger releases:
feat: add user authentication system       # Minor version bump
fix: resolve memory leak in data processing # Patch version bump
docs: update API documentation             # Patch version bump
style: fix linting issues in components    # Patch version bump
refactor: optimize database queries        # Patch version bump
test: add unit tests for user service      # Patch version bump
chore: update dependencies                 # Patch version bump

# Breaking changes (only allowed in v1.0.0+):
feat!: redesign authentication system      # Major version bump
```

## Version Progression

```bash
# Starting from no tags:
v0.1.0  # First release

# After feat commit:
v0.2.0  # Minor version bump

# After fix commit:
v0.2.1  # Patch version bump

# After reaching v1.0.0, breaking changes allowed:
feat!: new API design
v2.0.0  # Major version bump
```

## Encrypted Environment Files

The workflows expect these files in the repository root:
- `encrypted-aes-key.enc` - Encrypted AES key
- `encrypted-env-vars.enc` - Encrypted environment variables
- `encrypted-env-vars.meta` - Metadata and hash for integrity verification

## Workflow Behavior

### Pull Requests
- Run tests
- Run linting
- Build application
- Build Docker image (no push)

### Main Branch Push
- Run tests
- Run linting  
- Build application
- Generate semantic version
- Deploy secrets to AWS Secrets Manager
- Build and push Docker image to ECR
- Create git tag
- Create GitHub release