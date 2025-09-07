# ========================================
# VARIABLES FOR ARGOCD REPOSITORY SECRET MODULE
# ========================================

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the secret is stored"
  type        = string
  default     = "us-west-2"
}

variable "secret_name" {
  description = "Name of the AWS Secrets Manager secret"
  type        = string
  default     = "argocd-private-key"
}

variable "repository_url" {
  description = "Git repository URL (SSH format)"
  type        = string

  validation {
    condition     = can(regex("^git@", var.repository_url)) || can(regex("^ssh://", var.repository_url))
    error_message = "Repository URL must be in SSH format (git@... or ssh://...)."
  }
}

variable "secret_labels" {
  description = "Additional labels for the Kubernetes secret"
  type        = map(string)
  default     = {}
}

variable "namespace" {
  description = "Kubernetes namespace for the secret"
  type        = string
  default     = "argocd"
}

variable "kubernetes_secret_name" {
  description = "Name of the Kubernetes secret to create"
  type        = string
  default     = "private-repo-secret"
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}