locals {
  base_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "networking"
  }, var.tags)
}

module "vpc" {
  source       = "../../../modules/vpc"
  project_name = var.project_name
  environment  = var.environment
  cidr_block   = "10.10.0.0/16"
  public_subnets = {
    a = { cidr = "10.10.0.0/20", az = "${var.region}a" }
    b = { cidr = "10.10.16.0/20", az = "${var.region}b" }
  }
  private_subnets = {
    a = { cidr = "10.10.32.0/20", az = "${var.region}a" }
    b = { cidr = "10.10.48.0/20", az = "${var.region}b" }
  }
  tags = local.base_tags
}

output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnet_ids" { value = module.vpc.public_subnet_ids }
output "private_subnet_ids" { value = module.vpc.private_subnet_ids }
