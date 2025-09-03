# ========================================
# VARIABLES FOR SECRETS ACCESS IAM MODULE
# ========================================

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "allowed_secret_patterns" {
  description = "List of secret ARN patterns that pods can access"
  type        = list(string)
  default     = ["*"]

  validation {
    condition     = length(var.allowed_secret_patterns) > 0
    error_message = "At least one secret pattern must be specified."
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
