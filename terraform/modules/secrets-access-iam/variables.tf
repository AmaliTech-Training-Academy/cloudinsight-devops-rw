# ========================================
# VARIABLES FOR SECRETS ACCESS IAM MODULE
# ========================================

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "services" {
  description = "List of services with their secret access requirements"
  type = list(object({
    name        = string # Service name (e.g., "frontend", "user-service")
    secret_name = string # Single secret name this service can access
  }))

  validation {
    condition     = length(var.services) > 0
    error_message = "At least one service must be specified."
  }
}

variable "role_name_suffix" {
  description = "Suffix to append to the IAM role name"
  type        = string
  default     = "secrets-access"
}

variable "policy_name_suffix" {
  description = "Suffix to append to the IAM policy name"
  type        = string
  default     = "secrets-access"
}

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}
