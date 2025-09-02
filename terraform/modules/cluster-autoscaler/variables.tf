variable "cluster_name" { type = string }
variable "namespace" {
  type    = string
  default = "kube-system"
}
variable "service_account_name" {
  type    = string
  default = "cluster-autoscaler"
}
variable "chart_version" {
  type        = string
  description = "Helm chart version"
}
variable "repository" {
  type    = string
  default = "https://kubernetes.github.io/autoscaler"
}
variable "values_file" {
  type    = string
  default = ""
}
variable "extra_set" {
  type    = map(string)
  default = {}
}
variable "aws_region" { type = string }
