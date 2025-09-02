variable "cluster_name" {
  type = string
}
variable "region" {
  type = string
}
variable "namespace" {
  type    = string
  default = "cert-manager"
}
variable "release_name" {
  type    = string
  default = "cert-manager"
}
variable "chart_version" {
  type    = string
  default = "v1.14.5"
}
variable "repository" {
  type    = string
  default = "https://charts.jetstack.io"
}
variable "install_crds" {
  type    = bool
  default = true
}
variable "extra_set" {
  type    = map(string)
  default = {}
}
