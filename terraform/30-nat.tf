# Elastic Ip for Nat
resource "aws_eip" "nat" {
  domain = "vpc"
  depends_on = [ aws_internet_gateway.main ]
  tags = merge(local.common_tags,{Name = "${local.common_name}-nat-eip"})
}

# Nat gateway

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public.id
  depends_on = [ aws_internet_gateway.main ]
  tags = merge(local.common_tags,{Name="${local.common_name}-nat-gw"})
}