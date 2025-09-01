resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

output "igw_id" {
  value = aws_internet_gateway.this.id
}
