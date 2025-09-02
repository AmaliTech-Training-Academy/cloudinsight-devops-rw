variable "cluster_name" { type = string }

variable "namespace" {
  type    = string
  default = "kube-system"
}

variable "service_account_name" {
  type    = string
  default = "aws-load-balancer-controller"
}

variable "repository" {
  type    = string
  default = "https://aws.github.io/eks-charts"
}

variable "chart_version" {
  type        = string
  description = "Helm chart version (optional). If empty, latest will be used."
  default     = ""
}

variable "vpc_id" { type = string }
variable "region" { type = string }
