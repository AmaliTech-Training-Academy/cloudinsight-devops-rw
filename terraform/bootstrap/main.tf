terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  bucket_name = var.backend_bucket_name
  table_name  = var.lock_table_name
  cost_center = "${var.backend_bucket_name}-bootstrap"
  common_tags = {
    Project     = var.backend_bucket_name
    Environment = "bootstrap"
    CostCenter  = local.cost_center
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket" "tf_state" {
  bucket = local.bucket_name
  lifecycle {
    prevent_destroy = true
  }
  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  tags         = local.common_tags
  attribute {
    name = "LockID"
    type = "S"
  }
}

output "backend_bucket" {
  value = aws_s3_bucket.tf_state.bucket
}

output "lock_table" {
  value = aws_dynamodb_table.tf_locks.name
}
