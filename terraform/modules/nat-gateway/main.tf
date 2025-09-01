resource "aws_eip" "nat" {
  domain = "vpc"
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  })
}

resource "aws_nat_gateway" "this" {
  allocation_id     = aws_eip.nat.id
  subnet_id         = var.public_subnet_id
  connectivity_type = "public"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat"
  })

  # Caller should ensure IGW exists by ordering module calls; implicit dependency via subnet's VPC IGW attachment if any routes are added later.
}

output "nat_gateway_id" { value = aws_nat_gateway.this.id }
output "nat_eip_id" { value = aws_eip.nat.id }
output "nat_eip_public_ip" { value = aws_eip.nat.public_ip }
