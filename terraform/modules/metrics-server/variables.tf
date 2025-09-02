variable "name" {
  type        = string
  description = "Helm release name"
  default     = "metrics-server"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace to deploy metrics-server"
  default     = "kube-system"
}

variable "repository" {
  type        = string
  description = "Helm chart repository URL"
  default     = "https://kubernetes-sigs.github.io/metrics-server/"
}

variable "chart_version" {
  type        = string
  description = "Helm chart version (matches chart version, not app version)"
  default     = "3.13.0" # appVersion 0.8.0
}
