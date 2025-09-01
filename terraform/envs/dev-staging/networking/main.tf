locals {
  base_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "networking"
    CostCenter  = "${var.project_name}-${var.environment}"
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
  tags              = local.base_tags
  cluster_name      = var.cluster_name
  cluster_ownership = var.cluster_ownership
}

# Internet Gateway module
module "igw" {
  source       = "../../../modules/igw"
  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
  environment  = var.environment
  tags         = local.base_tags
}

output "igw_id" { value = module.igw.igw_id }

# NAT Gateway (single AZ for now - choose first public subnet)
module "nat_gateway" {
  source           = "../../../modules/nat-gateway"
  project_name     = var.project_name
  environment      = var.environment
  public_subnet_id = module.vpc.public_subnet_ids[0]
  tags             = local.base_tags
  depends_on       = [module.igw]
}

output "nat_gateway_id" { value = module.nat_gateway.nat_gateway_id }
output "nat_eip_id" { value = module.nat_gateway.nat_eip_id }
output "nat_eip_public_ip" { value = module.nat_gateway.nat_eip_public_ip }

output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnet_ids" { value = module.vpc.public_subnet_ids }
output "private_subnet_ids" { value = module.vpc.private_subnet_ids }

# Public route table with default route to IGW
resource "aws_route_table" "public" {
  vpc_id = module.vpc.vpc_id
  tags = merge(local.base_tags, {
    Name  = "${var.project_name}-${var.environment}-public-rt"
    Scope = "public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.igw.igw_id
}

resource "aws_route_table_association" "public" {
  for_each       = { for idx, id in module.vpc.public_subnet_ids : idx => id }
  subnet_id      = each.value
  route_table_id = aws_route_table.public.id
}

# Private route table with default route to NAT
resource "aws_route_table" "private" {
  vpc_id = module.vpc.vpc_id
  tags = merge(local.base_tags, {
    Name  = "${var.project_name}-${var.environment}-private-rt"
    Scope = "private"
  })
}

resource "aws_route" "private_egress" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = module.nat_gateway.nat_gateway_id
  depends_on             = [module.nat_gateway]
}

resource "aws_route_table_association" "private" {
  for_each       = { for idx, id in module.vpc.private_subnet_ids : idx => id }
  subnet_id      = each.value
  route_table_id = aws_route_table.private.id
}
