# Branch-Specific CODEOWNERS Templates

<div align="center">

![GitHub](https://img.shields.io/badge/GitHub-CODEOWNERS-181717?style=for-the-badge&logo=github)

</div>

This directory contains CODEOWNERS template files for different branches in CloudInsight repositories.

## 📋 Available Templates

| File                                             | Description                                 |
| ------------------------------------------------ | ------------------------------------------- |
| [CODEOWNERS.production](./CODEOWNERS.production) | CODEOWNERS template for production branches |
| [CODEOWNERS.staging](./CODEOWNERS.staging)       | CODEOWNERS template for staging branches    |

## 🔍 Template Contents

### Production Branch

The production branch CODEOWNERS file assigns ownership of all files to the production administrator:

```
# Production branch code owners
# Everything managed by production owner
* @bikaze
```

### Staging Branch

The staging branch CODEOWNERS file has specialized ownership rules:

```
# Staging branch code owners
# .github folder managed by bikaze
/.github/ @bikaze

# All other files managed by the staging owner
* @sntakirutimana72
```

## 🛠️ Usage

These templates are automatically applied by the `create-repos.sh` script during repository creation. The script copies the appropriate CODEOWNERS file to each branch.

## 📚 Detailed Documentation

For comprehensive documentation on CODEOWNERS and how they are implemented, refer to the main [dev-repo-setup README](../README.md).
