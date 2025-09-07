# Cluster name for the dev-staging environment
cluster_name = "cloudinsight-dev-staging"

# AWS region where resources are deployed
aws_region = "us-west-2"

# AWS Secrets Manager secret name containing SSH private key
secret_name = "argocd-private-key"

# Git repository URL in SSH format
repository_url = "git@github.com:AmaliTech-Training-Academy/cloudinsight-gitops-rw.git"

# Kubernetes namespace where ArgoCD is deployed
namespace = "argocd"

# Name for the Kubernetes secret
kubernetes_secret_name = "private-repo-secret"

# Additional labels for the secret
secret_labels = {
  repository = "cloudinsight-gitops"
  team       = "devops"
}

# Tags for AWS resources
tags = {
  Owner       = "DevOps Team"
  Project     = "CloudInsight"
  Environment = "dev-staging"
  Purpose     = "ArgoCD private repository access"
}