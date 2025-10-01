variable "cluster_name" { type = string }
variable "region" { type = string }
variable "namespace" { type = string }
variable "release_name" { type = string }
variable "chart_version" {
  type    = string
  default = ""
}
variable "repository" {
  type    = string
  default = "https://kubernetes.github.io/ingress-nginx"
}
variable "load_balancer_scheme" {
  type    = string
  default = "internet-facing"
}
variable "nlb_target_type" {
  type    = string
  default = "ip"
}
variable "service_annotations_extra" {
  type    = map(string)
  default = {}
}

variable "metrics_enabled" {
  type        = bool
  description = "Enable metrics collection for ingress-nginx controller"
  default     = true
}

variable "metrics_port" {
  type        = number
  description = "Port for metrics endpoint"
  default     = 10254
}
