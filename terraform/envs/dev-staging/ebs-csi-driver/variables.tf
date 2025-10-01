variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev-staging, production)"
}

variable "region" {
  type        = string
  description = "AWS region where resources will be created"
}

variable "addon_version" {
  type        = string
  description = "Pinned version of the aws-ebs-csi-driver addon"
  default     = "v1.48.0-eksbuild.2"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for the EBS CSI driver service account"
  default     = "kube-system"
}

variable "service_account_name" {
  type        = string
  description = "Name of the Kubernetes service account for the EBS CSI driver"
  default     = "ebs-csi-controller-sa"
}

variable "enable_encryption" {
  type        = bool
  description = "Whether to enable EBS encryption support for the CSI driver"
  default     = true
}

variable "resolve_conflicts_on_update" {
  type        = string
  description = "Conflict resolution strategy when updating the addon (NONE | OVERWRITE)"
  default     = "OVERWRITE"
}

variable "resolve_conflicts_on_create" {
  type        = string
  description = "Conflict resolution strategy when creating the addon (NONE | OVERWRITE)"
  default     = "NONE"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to resources"
  default     = {}
}
