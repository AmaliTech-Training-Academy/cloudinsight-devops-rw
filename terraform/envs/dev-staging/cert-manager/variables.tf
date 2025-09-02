variable "release_name" {
  type    = string
  default = "cert-manager"
}
variable "namespace" {
  type    = string
  default = "cert-manager"
}
variable "chart_version" {
  type    = string
  default = "v1.18.2"
}
variable "install_crds" {
  type    = bool
  default = true
}
variable "extra_set" {
  type    = map(string)
  default = {}
}
