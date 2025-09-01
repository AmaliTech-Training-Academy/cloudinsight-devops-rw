resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = merge(
    var.tags,
    {
      Name                                        = "${var.project_name}-${var.environment}-public-${each.key}"
      Tier                                        = "public"
      "kubernetes.io/cluster/${var.cluster_name}" = var.cluster_ownership
      "kubernetes.io/role/elb"                    = "1"
    }
  )
}

resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags = merge(
    var.tags,
    {
      Name                                        = "${var.project_name}-${var.environment}-private-${each.key}"
      Tier                                        = "private"
      "kubernetes.io/cluster/${var.cluster_name}" = var.cluster_ownership
      "kubernetes.io/role/internal-elb"           = "1"
    }
  )
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}
