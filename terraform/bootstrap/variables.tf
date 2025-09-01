variable "region" {
  description = "AWS region for backend resources"
  type        = string
}

variable "backend_bucket_name" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
}
