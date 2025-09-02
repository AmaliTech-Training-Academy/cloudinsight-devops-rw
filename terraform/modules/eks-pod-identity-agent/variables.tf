variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster to attach the Pod Identity Agent addon to"
}

variable "addon_version" {
  type        = string
  description = "Pinned version of the eks-pod-identity-agent addon"
  default     = "v1.3.8-eksbuild.2"
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
  description = "Tags to apply to the addon (propagated to underlying resources where supported)"
  default     = {}
}
