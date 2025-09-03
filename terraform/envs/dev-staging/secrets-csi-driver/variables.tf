variable "region" {
  type = string
}
variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}
variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "tags" {
  type = map(string)
}

variable "csi_driver_version" {
  description = "Version of the Secrets Store CSI Driver Helm chart"
  type        = string
  default     = "1.4.6"
}

variable "aws_provider_version" {
  description = "Version of the AWS Secrets Manager CSI Provider Helm chart"
  type        = string
  default     = "0.3.9"
}

variable "sync_secret_enabled" {
  description = "Enable syncing secrets to Kubernetes secrets"
  type        = bool
  default     = true
}

variable "enable_secret_rotation" {
  description = "Enable automatic secret rotation"
  type        = bool
  default     = true
}

variable "rotation_poll_interval" {
  description = "Interval for polling secret rotation"
  type        = string
  default     = "2m"
}
