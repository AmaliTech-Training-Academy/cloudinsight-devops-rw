# Repository Templates

<div align="center">

![GitHub](https://img.shields.io/badge/GitHub-Templates-181717?style=for-the-badge&logo=github)

</div>

This directory contains standardized templates for CloudInsight repositories. These templates are used by the `create-repos.sh` script to initialize new repositories with consistent structure and documentation.

## 📋 Available Templates

| Template               | Description                        |
| ---------------------- | ---------------------------------- |
| [frontend](./frontend) | Template for frontend repositories |
| [backend](./backend)   | Template for backend repositories  |

## 📂 Template Structure

Each template contains:

- **README.md**: A standardized README file with project documentation
- **.github/workflows/ci.yml**: Continuous integration workflow configuration

### Frontend Template

The frontend template includes:

- Project overview for frontend applications
- Setup and installation instructions
- Development workflows
- CI/CD configuration for frontend technologies

### Backend Template

The backend template includes:

- Project overview for backend services
- API documentation structure
- Database configuration information
- CI/CD configuration for backend technologies

## 🛠️ Usage

These templates are automatically applied by the `create-repos.sh` script during repository creation. The script selects the appropriate template based on the repository type specified in the configuration.

## 📚 Detailed Documentation

For comprehensive documentation on how templates are applied, refer to the main [dev-repo-setup README](../README.md).
