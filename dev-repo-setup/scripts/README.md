# CloudInsight Repository Management Scripts

<div align="center">

![Bash Scripts](https://img.shields.io/badge/Bash-Scripts-4EAA25?style=for-the-badge&logo=gnu-bash)
![GitHub CLI](https://img.shields.io/badge/GitHub-CLI-181717?style=for-the-badge&logo=github)

</div>

This directory contains bash scripts for automating GitHub repository management tasks for the CloudInsight project.

## 📋 Available Scripts

### 🛠️ Repository Management

| Script                                                       | Description                                                                   |
| ------------------------------------------------------------ | ----------------------------------------------------------------------------- |
| [create-repos.sh](./create-repos.sh)                         | Creates and configures repositories with standardized branches and CODEOWNERS |
| [manage-branch-protection.sh](./manage-branch-protection.sh) | Manages branch protection with CODEOWNERS enforcement                         |
| [manage-repo-visibility.sh](./manage-repo-visibility.sh)     | Controls repository visibility settings                                       |

### 🔐 Security & Environment Management

| Script                                                               | Description                                                                      |
| -------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| [encrypt-env-vars-team.sh](./encrypt-env-vars-team.sh)               | 🔒 **Developer Script**: Encrypts environment variables for secure Git storage   |
| [decrypt-env-vars-team.sh](./decrypt-env-vars-team.sh)               | 🔓 **Team Lead Script**: Decrypts environment variables using private key        |
| [manage-repo-secrets.sh](./manage-repo-secrets.sh)                   | 🔑 **Secrets Manager**: Interactive bulk deployment of GitHub repository secrets |
| [distribute-encryption-script.sh](./distribute-encryption-script.sh) | 📤 Distributes encryption script to all team repositories                        |

## 📑 Additional Files

### 📋 Configuration Files

| File                                                         | Description                                                          |
| ------------------------------------------------------------ | -------------------------------------------------------------------- |
| [branch-protection-rules.txt](./branch-protection-rules.txt) | Contains a list enabled configuration for branch protection settings |

### 🔐 Security Files

| File                                         | Description                                             |
| -------------------------------------------- | ------------------------------------------------------- |
| [team-public-key.pem](./team-public-key.pem) | RSA public key for team environment variable encryption |
| [sample.env](./sample.env)                   | Example environment variables file for testing          |

### 📖 Documentation

| File                                                     | Description                                                         |
| -------------------------------------------------------- | ------------------------------------------------------------------- |
| [README-TEAM-ENCRYPTION.md](./README-TEAM-ENCRYPTION.md) | 📘 **Complete Guide**: Team environment variables encryption system |

## 🔧 Usage

### Repository Management Scripts

All repository management scripts support the `--help` flag to display usage instructions:

```bash
./create-repos.sh --help
./manage-branch-protection.sh --help
./manage-repo-visibility.sh --help
```

### Environment Variables Encryption

#### For Developers (Encrypt .env files):

```bash
# Make script executable and run (can be run from anywhere in repository)
chmod +x scripts/encrypt-env-vars-team.sh
./scripts/encrypt-env-vars-team.sh

# Follow prompts to encrypt your .env file
# Files created in repository root: encrypted-env-vars.enc, encrypted-aes-key.enc, encrypted-env-vars.meta
# Commit the generated encrypted files to Git
```

#### For Team Lead (Decrypt .env files):

```bash
# Run decryption script with private key (looks for files in repository root)
./decrypt-env-vars-team.sh

# Follow prompts to decrypt environment files
```

#### Repository Secrets Management:

```bash
# Set GitHub repository secrets across all repositories
./manage-repo-secrets.sh

# Interactive prompts for secret names and values
# Applies secrets to all repositories in the REPOS list
```

#### Distribution to All Repositories:

```bash
# Distribute encryption script to all team repositories
./distribute-encryption-script.sh
```

📖 **Complete encryption guide**: [README-TEAM-ENCRYPTION.md](./README-TEAM-ENCRYPTION.md)

## 🔑 Prerequisites

### Basic Requirements

- GitHub CLI (`gh`) installed and authenticated
- Git installed
- Admin access to the organization's repositories

### For Environment Variable Encryption

- OpenSSL (auto-installed by scripts)
- Access to team private key (team lead only)
- Write access to target repositories (for distribution)

## 🚀 Quick Start

### 1. Repository Setup

```bash
# Create all project repositories
./create-repos.sh

# Apply branch protection rules
./manage-branch-protection.sh
```

### 2. Environment Variables Security

```bash
# Distribute encryption script to all repositories
./distribute-encryption-script.sh

# Developers can then encrypt their .env files
./encrypt-env-vars-team.sh
```

## 📚 Detailed Documentation

For comprehensive documentation on each script, refer to the main [dev-repo-setup README](../README.md).
