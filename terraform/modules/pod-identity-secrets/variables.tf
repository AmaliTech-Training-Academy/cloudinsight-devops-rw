# ========================================
# VARIABLES FOR POD IDENTITY SECRETS MODULE
# ========================================

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "microservices" {
  description = "List of microservices with their namespace, service account, and IAM role ARN"
  type = list(object({
    name            = string
    namespace       = string
    service_account = string
    role_arn        = string # Service-specific IAM role ARN
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
