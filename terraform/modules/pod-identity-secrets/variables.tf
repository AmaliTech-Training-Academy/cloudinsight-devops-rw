# ========================================
# VARIABLES FOR POD IDENTITY SECRETS MODULE
# ========================================

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "secrets_role_arn" {
  description = "ARN of the IAM role for secrets access (from secrets-access-iam module)"
  type        = string
}

variable "microservices" {
  description = "List of microservices with their namespace and service account"
  type = list(object({
    name            = string
    namespace       = string
    service_account = string
  }))

  validation {
    condition     = length(var.microservices) > 0
    error_message = "At least one microservice must be specified."
  }
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}
