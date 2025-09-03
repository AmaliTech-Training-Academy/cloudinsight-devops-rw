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

variable "server_insecure" {
  description = "Whether to run ArgoCD server in insecure mode (for TLS termination at ingress)"
  type        = bool
  default     = true
}

variable "custom_values" {
  description = "Additional custom values to merge with the default ArgoCD configuration"
  type        = any
  default     = {}
}
