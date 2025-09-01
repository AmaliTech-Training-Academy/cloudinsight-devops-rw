variable "environment" {
  type        = string
  description = "Fixed environment identifier (dev-staging)"
  validation {
    condition     = var.environment == "dev-staging"
    error_message = "environment must be dev-staging"
  }
}

variable "project_name" {
  type        = string
  description = "Project name prefix"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "tags" {
  type        = map(string)
  description = "Additional resource tags"
}
