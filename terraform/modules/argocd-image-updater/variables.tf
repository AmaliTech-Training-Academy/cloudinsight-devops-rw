# Helm Release Configuration
variable "release_name" {
  description = "The name of the ArgoCD Image Updater Helm release"
  type        = string
  default     = "argocd-image-updater"
}

variable "repository" {
  description = "The Helm repository URL"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
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

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
  default     = false
}

variable "timeout" {
  description = "Timeout for Helm deployment in seconds"
  type        = number
  default     = 600
}

# Service Account Configuration
variable "service_account_name" {
  description = "The name of the service account for ArgoCD Image Updater"
  type        = string
  default     = "argocd-image-updater"
}

# Image Configuration
variable "image_repository" {
  description = "The image repository for ArgoCD Image Updater"
  type        = string
  default     = "quay.io/argoprojlabs/argocd-image-updater"
}

# Resource Configuration
variable "cpu_limit" {
  description = "CPU limit for the image updater container"
  type        = string
  default     = "100m"
}

variable "memory_limit" {
  description = "Memory limit for the image updater container"
  type        = string
  default     = "128Mi"
}

variable "cpu_request" {
  description = "CPU request for the image updater container"
  type        = string
  default     = "50m"
}

variable "memory_request" {
  description = "Memory request for the image updater container"
  type        = string
  default     = "64Mi"
}

# Auth Scripts Configuration
variable "auth_scripts_enabled" {
  description = "Whether to enable auth scripts for ECR authentication"
  type        = bool
  default     = true
}

variable "auth_scripts" {
  description = "Map of auth script names to their content"
  type        = map(string)
  default     = {}
}

# Registry Configuration
variable "registries" {
  description = "List of registry configurations for image updater"
  type        = list(any)
  default     = []
}

# Logging Configuration
variable "log_level" {
  description = "Log level for ArgoCD Image Updater"
  type        = string
  default     = "info"

  validation {
    condition     = contains(["trace", "debug", "info", "warn", "error", "fatal", "panic"], var.log_level)
    error_message = "Log level must be one of: trace, debug, info, warn, error, fatal, panic."
  }
}

# Metrics Configuration
variable "metrics_enabled" {
  description = "Whether to enable metrics for ArgoCD Image Updater"
  type        = bool
  default     = true
}

variable "metrics_port" {
  description = "Port for metrics endpoint"
  type        = number
  default     = 8080
}

# Custom Values
variable "custom_values" {
  description = "Additional custom values to merge with defaults"
  type        = any
  default     = {}
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
