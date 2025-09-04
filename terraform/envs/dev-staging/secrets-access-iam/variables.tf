# ========================================
# VARIABLES FOR SECRETS ACCESS IAM - DEV/STAGING
# ========================================

variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "services" {
  description = "List of services with their secret access requirements"
  type = list(object({
    name        = string
    secret_name = string
  }))
}
