# CloudInsight Repository Management Scripts

<div align="center">

![Bash Scripts](https://img.shields.io/badge/Bash-Scripts-4EAA25?style=for-the-badge&logo=gnu-bash)
![GitHub CLI](https://img.shields.io/badge/GitHub-CLI-181717?style=for-the-badge&logo=github)

</div>

This directory contains bash scripts for automating GitHub repository management tasks for the CloudInsight project.

## 📋 Available Scripts

| Script                                                       | Description                                                                   |
| ------------------------------------------------------------ | ----------------------------------------------------------------------------- |
| [create-repos.sh](./create-repos.sh)                         | Creates and configures repositories with standardized branches and CODEOWNERS |
| [manage-branch-protection.sh](./manage-branch-protection.sh) | Manages branch protection with CODEOWNERS enforcement                         |
| [manage-repo-visibility.sh](./manage-repo-visibility.sh)     | Controls repository visibility settings                                       |

## 📑 Additional Files

| File                                                         | Description                                                    |
| ------------------------------------------------------------ | -------------------------------------------------------------- |
| [branch-protection-rules.txt](./branch-protection-rules.txt) | Contains a list enabled configuration for branch protection settings |

## 🔧 Usage

All scripts support the `--help` flag to display usage instructions:

```bash
./create-repos.sh --help
./manage-branch-protection.sh --help
./manage-repo-visibility.sh --help
```

## 🔑 Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Git installed
- Admin access to the organization's repositories

## 📚 Detailed Documentation

For comprehensive documentation on each script, refer to the main [dev-repo-setup README](../README.md).
