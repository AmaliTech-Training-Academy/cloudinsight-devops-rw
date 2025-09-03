variable "project_name" {
  description = "Project name for naming resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev-staging, production, etc.)"
  type        = string
}

variable "repositories" {
  description = "List of ECR repository configurations"
  type = list(object({
    name = string
    type = string # frontend or backend
  }))
  default = [
    {
      name = "cloudinsight-frontend"
      type = "frontend"
    },
    {
      name = "cloudinsight-api-gateway"
      type = "backend"
    },
    {
      name = "cloudinsight-service-discovery"
      type = "backend"
    },
    {
      name = "cloudinsight-config-server"
      type = "backend"
    },
    {
      name = "cloudinsight-user-service"
      type = "backend"
    },
    {
      name = "cloudinsight-cost-service"
      type = "backend"
    },
    {
      name = "cloudinsight-metric-service"
      type = "backend"
    },
    {
      name = "cloudinsight-anomaly-service"
      type = "backend"
    },
    {
      name = "cloudinsight-forecast-service"
      type = "backend"
    },
    {
      name = "cloudinsight-notification-service"
      type = "backend"
    }
  ]
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "lifecycle_policy" {
  description = "Lifecycle policy for ECR repositories"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
