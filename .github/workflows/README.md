# Reusable GitHub Actions Workflows

This directory contains a comprehensive set of reusable GitHub Actions workflows implementing a modern CI/CD pipeline strategy for the CloudInsight project.

## 🏗️ Architecture Overview

The workflow architecture follows a **Reusable Workflows** pattern with the following components:

```
Main Orchestrator Workflows
├── main-ci-backend.yml     # Backend CI/CD orchestrator
└── main-ci-frontend.yml    # Frontend CI/CD orchestrator

Reusable Workflow Components  
├── security-scan.yml       # Security scanning (SonarQube + Trivy)
├── build.yml              # Generic build workflow
└── deploy.yml             # Deployment workflow (AWS integration)
```

## 🚀 Main Orchestrator Workflows

### Backend Pipeline (`main-ci-backend.yml`)
- **Purpose**: Orchestrates the complete backend CI/CD pipeline
- **Triggers**: Push to any branch, Pull requests, Manual dispatch
- **Features**: Comment filtering, security scanning, build, test, deploy

### Frontend Pipeline (`main-ci-frontend.yml`)  
- **Purpose**: Orchestrates the complete frontend CI/CD pipeline
- **Triggers**: Push to any branch, Pull requests, Manual dispatch
- **Features**: Comment filtering, security scanning, build, test, deploy

## 🧩 Reusable Workflow Components

### 1. Security Scanning (`security-scan.yml`)

**Purpose**: Comprehensive security analysis with SonarQube and Trivy

**Features:**
- SonarQube code quality analysis with quality gate enforcement
- Trivy vulnerability scanning for containers and filesystems
- SARIF report upload to GitHub Security tab
- Configurable severity thresholds
- Support for both frontend and backend projects

**Inputs:**
```yaml
project_type: frontend|backend        # Required
sonar_project_key: string            # Optional override
trivy_severity: string               # Default: HIGH,CRITICAL
skip_quality_gate: boolean          # Default: false
```

**Required Secrets:**
```yaml
SONARQUBE_URL: https://sonar.example.com
SONARQUBE_TOKEN: your_sonar_token
SONARQUBE_PROJECT_KEY: project-key   # Optional
TRIVY_SERVER_URL: trivy_server       # Optional
TRIVY_TOKEN: trivy_token             # Optional
```

### 2. Build Workflow (`build.yml`)

**Purpose**: Generic build workflow supporting both frontend and backend projects

**Features:**
- Java/Maven builds for backend projects
- Node.js/pnpm builds for frontend projects
- Multi-platform Docker image building (linux/amd64, linux/arm64)
- AWS ECR integration with automatic image push
- Test execution with coverage reporting
- Encrypted environment variable decryption
- Artifact management and metadata generation

**Inputs:**
```yaml
project_type: frontend|backend       # Required
environment: string                  # Default: development
push_to_ecr: boolean                # Default: false
run_tests: boolean                  # Default: true
docker_platforms: string           # Default: linux/amd64,linux/arm64
```

**Required Secrets (for ECR):**
```yaml
AWS_REGION: us-east-1
AWS_ACCESS_KEY_ID: your_access_key
AWS_SECRET_ACCESS_KEY: your_secret_key
ECR_REPOSITORY_NAME: your_ecr_repo
TEAM_PRIVATE_KEY: rsa_private_key    # For environment decryption
```

**Outputs:**
- Built Docker image tags and digests
- ECR image URI (if pushed)
- Test execution results
- Build metadata for ArgoCD

### 3. Deploy Workflow (`deploy.yml`)

**Purpose**: Environment deployment with AWS Secrets Manager integration

**Features:**
- AWS Secrets Manager secret deployment with merge capability
- ArgoCD configuration generation
- Environment-specific deployment logic
- Deployment validation and health checks
- Support for multiple deployment strategies

**Inputs:**
```yaml
project_type: frontend|backend       # Required
environment: string                  # Required
deploy_secrets: boolean             # Default: false
secrets_merge_strategy: merge|replace # Default: merge
```

**Required Secrets:**
```yaml
AWS_REGION: us-east-1
AWS_ACCESS_KEY_ID: your_access_key
AWS_SECRET_ACCESS_KEY: your_secret_key
AWS_SECRETS_MANAGER_SECRET_NAME: secret_name  # Optional
DEPLOYMENT_SECRETS: {"key": "value"}          # Optional JSON
```

## 🔒 Secret Management Strategy

### Required GitHub Repository Secrets

#### AWS Configuration
```bash
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
ECR_REPOSITORY_NAME=cloudinsight-app
```

#### Security Tools
```bash
SONARQUBE_URL=https://sonarqube.example.com
SONARQUBE_TOKEN=squ_...
SONARQUBE_PROJECT_KEY=cloudinsight-backend  # Optional
TRIVY_SERVER_URL=https://trivy.example.com  # Optional
TRIVY_TOKEN=...                             # Optional
```

#### Deployment
```bash
AWS_SECRETS_MANAGER_SECRET_NAME=cloudinsight/production
DEPLOYMENT_SECRETS={"DATABASE_URL":"...", "API_KEY":"..."}
TEAM_PRIVATE_KEY=-----BEGIN RSA PRIVATE KEY-----...
```

## 📦 Artifact Management

The workflows implement comprehensive artifact passing:

### Build Artifacts
- **Application binaries**: JAR files, Node.js builds
- **Docker images**: Multi-platform container images
- **Test reports**: JUnit XML, coverage reports (JaCoCo, LCOV)
- **Build metadata**: Image URIs, tags, environment info

### Security Artifacts
- **SonarQube reports**: Quality gate results, code metrics
- **Trivy reports**: SARIF vulnerability reports, security summaries

### Deployment Artifacts
- **ArgoCD configurations**: Application manifests, image updates
- **Environment metadata**: Deployment status, timestamps

## 🛡️ Enhanced Features

### 1. Comment Filtering
Workflows automatically skip execution when only documentation or comment files are changed:

```yaml
paths-ignore:
  - '**.md'
  - '**.txt'
  - '.gitignore'
  - 'docs/**'
  - 'README*'
```

### 2. Quality Gates
- **SonarQube**: Configurable quality gate with analysis waiting
- **Trivy**: Vulnerability threshold enforcement
- **Test Coverage**: Automatic coverage reporting and thresholds

### 3. Multi-Environment Support
```yaml
# Automatic environment detection based on branch
environment: |
  ${{ 
    github.ref == 'refs/heads/production' && 'production' || 
    github.ref == 'refs/heads/staging' && 'staging' || 
    'development' 
  }}
```

### 4. ECR Integration
Automatic image pushing to AWS ECR with proper tagging:

```yaml
tags: |
  type=ref,event=branch
  type=sha,prefix={{branch}}-
  type=raw,value=latest,enable={{is_default_branch}}
  type=raw,value=${{ environment }}
```

### 5. Secrets Merging
AWS Secrets Manager integration with merge capability to preserve existing secrets:

```bash
# Existing secrets are preserved, new ones are added/updated
existing_secrets=$(aws secretsmanager get-secret-value ...)
merged_secrets=$(echo "$existing_secrets" "$new_secrets" | jq -s '.[0] * .[1]')
```

## 🔄 Migration from Legacy Workflows

The original workflows in `/workflows/backend/ci.yml` and `/workflows/frontend/ci.yml` contain all the existing functionality, which has been preserved and enhanced in the new reusable workflow structure.

### Key Improvements
1. **Reduced duplication**: Common patterns extracted into reusable components
2. **Enhanced security**: Dedicated security scanning stage
3. **Better artifact management**: Structured artifact passing between stages
4. **Environment support**: Multi-environment deployment strategy
5. **Comment filtering**: Skip CI for documentation-only changes
6. **Manual controls**: Workflow dispatch with granular options

### Preserved Functionality
- ✅ Java/Maven backend builds with JaCoCo coverage
- ✅ Node.js/pnpm frontend builds with Vitest
- ✅ Multi-platform Docker builds
- ✅ Encrypted environment variable decryption
- ✅ Test reporting and annotations
- ✅ Artifact upload and management
- ✅ Coverage summaries and reporting

## 🎯 Usage Examples

### Basic Usage (Automatic)
Workflows trigger automatically on push/PR:

```yaml
# Simply push code - workflow detects project type and runs appropriate pipeline
git push origin feature-branch
```

### Manual Deployment
Use workflow dispatch for controlled deployments:

```yaml
# Trigger via GitHub UI or CLI
gh workflow run main-ci-backend.yml \
  --field environment=staging \
  --field push_to_ecr=true \
  --field deploy_to_environment=true
```

### Security-Only Scan
Run just security scanning:

```yaml
# Call reusable workflow directly
uses: ./.github/workflows/security-scan.yml
with:
  project_type: backend
  trivy_severity: CRITICAL
secrets:
  SONARQUBE_URL: ${{ secrets.SONARQUBE_URL }}
  SONARQUBE_TOKEN: ${{ secrets.SONARQUBE_TOKEN }}
```

## 🏷️ Labels and Annotations

All images are built with comprehensive metadata:

```yaml
labels:
  org.opencontainers.image.title=CloudInsight Backend
  org.opencontainers.image.vendor=AmaliTech Training Academy
  cloudinsight.project.type=backend
  cloudinsight.project.environment=production
  cloudinsight.build.timestamp=2024-01-01T12:00:00Z
```

## 📊 Monitoring and Observability

### Pipeline Summaries
Each workflow provides detailed summaries:
- Stage-by-stage results
- Test coverage metrics
- Security scan results
- Deployment status
- Next steps and recommendations

### GitHub Integration
- Security tab integration for vulnerability reports
- Checks API integration for status reporting
- Artifact storage with configurable retention
- Action logs with structured output

## 🔧 Configuration

### Repository Setup
1. Add required secrets to repository settings
2. Ensure Docker buildx is available
3. Configure AWS credentials with appropriate permissions
4. Set up SonarQube project and quality gates

### Environment Variables
```bash
# Frontend-specific
NEXT_PUBLIC_API_BASE_URL=https://api.example.com
NEXT_PUBLIC_NODE_ENV=production

# Backend-specific  
SPRING_PROFILES_ACTIVE=production
SERVER_PORT=8080
```

## 🚀 Future Enhancements

Planned improvements:
- [ ] Integration testing stage
- [ ] Performance testing automation
- [ ] Blue-green deployment support
- [ ] Rollback automation
- [ ] Slack/Teams notifications
- [ ] Dependency vulnerability monitoring
- [ ] License compliance checking

---

This reusable workflow architecture provides a robust, scalable, and maintainable CI/CD pipeline that grows with your project needs while maintaining security and reliability standards.