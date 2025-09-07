variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "services" {
  description = "List of services that need secrets access"
  type = list(object({
    name            = string
    namespace       = string
    service_account = string
  }))
  default = []
}

variable "secrets_arns" {
  description = "List of secret ARNs that services can access"
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
