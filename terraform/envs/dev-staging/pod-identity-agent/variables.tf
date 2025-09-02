variable "project_name" { type = string }
variable "environment" { type = string }
variable "region" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

variable "addon_version" {
  type        = string
  description = "eks-pod-identity-agent addon version to deploy"
  default     = "v1.3.8-eksbuild.2"
}
