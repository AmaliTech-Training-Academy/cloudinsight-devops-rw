# ========================================
# VARIABLES FOR ARGOCD REPOSITORY SECRET - DEV/STAGING
# ========================================

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "cloudinsight-dev-staging"
}

variable "aws_region" {
  description = "AWS region where the secret is stored"
  type        = string
  default     = "us-west-2"
}

variable "secret_name" {
  description = "Name of the AWS Secrets Manager secret containing the SSH private key"
  type        = string
  default     = "argocd-private-key"
}

variable "repository_url" {
  description = "Git repository URL (SSH format) for the private repository"
  type        = string
  default     = "git@github.com:AmaliTech-Training-Academy/cloudinsight-gitops-rw.git"
}

variable "namespace" {
  description = "Kubernetes namespace for the ArgoCD repository secret"
  type        = string
  default     = "argocd"
}

variable "kubernetes_secret_name" {
  description = "Name of the Kubernetes secret to create"
  type        = string
  default     = "private-repo-secret"
}

variable "secret_labels" {
  description = "Additional labels for the Kubernetes secret"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}