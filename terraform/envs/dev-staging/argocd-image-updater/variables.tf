# Common variables
variable "region" {
  description = "AWS region"
  type        = string
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
}

# ArgoCD Image Updater specific variables
variable "release_name" {
  description = "The name of the ArgoCD Image Updater Helm release"
  type        = string
  default     = "argocd-image-updater"
}

variable "chart_version" {
  description = "The version of the ArgoCD Image Updater Helm chart"
  type        = string
  default     = "0.12.3"
}

variable "namespace" {
  description = "The namespace where ArgoCD Image Updater will be deployed"
  type        = string
  default     = "argocd"
}

variable "service_account_name" {
  description = "The name of the service account for ArgoCD Image Updater"
  type        = string
  default     = "argocd-image-updater"
}

# Resource configuration
variable "cpu_limit" {
  description = "CPU limit for the image updater container"
  type        = string
  default     = "200m"
}

variable "memory_limit" {
  description = "Memory limit for the image updater container"
  type        = string
  default     = "256Mi"
}

variable "cpu_request" {
  description = "CPU request for the image updater container"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for the image updater container"
  type        = string
  default     = "128Mi"
}

# Configuration
variable "log_level" {
  description = "Log level for ArgoCD Image Updater"
  type        = string
  default     = "info"
}

variable "metrics_enabled" {
  description = "Whether to enable metrics for ArgoCD Image Updater"
  type        = bool
  default     = true
}

variable "custom_values" {
  description = "Additional custom values to merge with defaults"
  type        = any
  default     = {}
}
