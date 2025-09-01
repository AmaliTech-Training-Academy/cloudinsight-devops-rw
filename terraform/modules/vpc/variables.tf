variable "project_name" { type = string }
variable "environment" { type = string }
variable "cidr_block" { type = string }

variable "public_subnets" {
  description = "Map of public subnet definitions: key => { cidr, az }"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "private_subnets" {
  description = "Map of private subnet definitions: key => { cidr, az }"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "tags" {
  type        = map(string)
  description = "Additional tags"
}
