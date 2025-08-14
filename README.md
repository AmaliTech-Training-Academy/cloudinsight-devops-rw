# CloudInsight DevOps Repository

![CloudInsight](https://img.shields.io/badge/CloudInsight-DevOps-blue?style=for-the-badge)
![GitHub](https://img.shields.io/badge/GitHub-Repository-181717?style=for-the-badge&logo=github)

This repository contains DevOps tools and automation for the CloudInsight project. These tools help standardize repository structures, enforce best practices, and simplify management tasks for the CloudInsight project.

## 📋 Repository Contents

### [DevOps Repository Setup](/dev-repo-setup)

The `dev-repo-setup` directory contains tools for automating GitHub repository setup and management for CloudInsight projects:

- **Repository Creation**: Automates the creation and configuration of standardized repositories
- **Branch Protection**: Tools to manage branch protection rules with CODEOWNERS enforcement
- **Repository Visibility**: Scripts to manage repository visibility settings (public/private)
- **CODEOWNERS Templates**: Standard ownership templates for different branches
- **Repository Templates**: Frontend and backend repository templates

#### Key Scripts

| Script                                                                             | Description                                                                   |
| ---------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| [create-repos.sh](/dev-repo-setup/scripts/create-repos.sh)                         | Creates and configures repositories with standardized branches and CODEOWNERS |
| [manage-branch-protection.sh](/dev-repo-setup/scripts/manage-branch-protection.sh) | Manages branch protection with CODEOWNERS enforcement                         |
| [manage-repo-visibility.sh](/dev-repo-setup/scripts/manage-repo-visibility.sh)     | Controls repository visibility settings                                       |

For detailed documentation on these tools, see the [dev-repo-setup README](/dev-repo-setup/README.md).

### [Architecture Documentation](/architecture)

The `architecture` directory contains comprehensive documentation of the CloudInsight infrastructure and CI/CD pipeline:

- **Infrastructure Architecture**: Multi-tier AWS cloud architecture using EKS, RDS, DocumentDB, and MSK
- **CI/CD Pipeline**: GitOps-based deployment pipeline with GitHub Actions and ArgoCD
- **Security Framework**: Comprehensive security controls including WAF, Shield, and secret management
- **Multi-Environment Strategy**: Development, Staging, and Production environment configurations

![CI/CD Architecture](./architecture/cicd-architecture.png)

![Infrastructure Architecture](./architecture/infra-architecture.png)

#### Architecture Highlights

- **Multi-AZ Deployment**: High availability across 2 availability zones
- **Microservices**: Frontend, User, Cost, Metric, Anomaly, Forecast, and Notification services
- **Database Strategy**: PostgreSQL RDS for user data, DocumentDB for other backend microservices
- **Event Streaming**: Amazon MSK (Kafka) for asynchronous communication
- **GitOps Deployment**: ArgoCD for automated, declarative deployments
- **Security**: WAF, Shield, TLS encryption, and secret management
- **Monitoring**: Prometheus, Grafana, and CloudWatch integration

For detailed architecture documentation, see the [Architecture README](/architecture/README.md).

## 🚀 Getting Started

1. Clone this repository:

   ```bash
   git clone https://github.com/AmaliTech-Training-Academy/cloudinsight-devops-rw.git
   cd cloudinsight-devops-rw
   ```

2. Navigate to the desired tool directory:

   ```bash
   cd dev-repo-setup/scripts
   ```

3. Make scripts executable:

   ```bash
   chmod +x *.sh
   ```

4. Run the desired script:
   ```bash
   ./create-repos.sh --help
   ```

---

<div align="center">
<p>Developed with ❤️ by the CloudInsight DevOps Team</p>
</div>
