variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster to attach the EBS CSI driver addon to"
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
  description = "Tags to apply to the resources (propagated to underlying resources where supported)"
  default     = {}
}
