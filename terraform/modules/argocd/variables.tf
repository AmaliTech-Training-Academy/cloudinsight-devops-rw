variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "release_name" {
  description = "Helm release name for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "8.3.3"
}

variable "repository" {
  description = "Helm repository URL"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

variable "server_insecure" {
  description = "Whether to run ArgoCD server in insecure mode (for TLS termination at ingress)"
  type        = bool
  default     = true
}

variable "admin_password_secret_name" {
  description = "Name of the Kubernetes secret containing the admin password"
  type        = string
  default     = "argocd-initial-admin-secret"
}

variable "custom_values" {
  description = "Additional custom values to merge with the default ArgoCD configuration"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}
