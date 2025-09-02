variable "project_name" { type = string }
variable "environment" { type = string }
variable "region" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig file used by helm provider"
  default     = "~/.kube/config"
}

variable "chart_version" { type = string }
