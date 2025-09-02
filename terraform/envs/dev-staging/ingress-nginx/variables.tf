variable "release_name" {
  type    = string
  default = "external-nginx"
}
variable "namespace" {
  type    = string
  default = "ingress"
}
variable "chart_version" {
  type = string
  # Upgraded to latest stable ingress-nginx Helm chart version compatible with AWS LB Controller
  # (annotations used remain valid). Previous: 4.10.1
  default = "4.13.2"
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
