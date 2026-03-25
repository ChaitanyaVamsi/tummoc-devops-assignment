# vpc
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = merge(local.common_tags,{
    Name = "${local.common_name}-vpc"
  })
}

# IGW
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
    tags = merge(local.common_tags ,{
    Name = "${local.common_name}-igw"
  })
}

# subnets
# Public subnet - ALB,NAT,Bastion
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
  tags =merge(local.common_tags,{
    Name = "${local.common_name}-public-subnet"
  })

}

# private subent - app EC2 , no internet

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = false
  tags = merge(local.common_tags,{
    Name = "${local.common_name}-private-subnet"
  })
}

# Route tables
# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags =merge(local.common_tags,{
    Name = "${local.common_name}-public-rt"
  })
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main.id
  }
  tags =merge(local.common_tags, {
    Name = "${local.common_name}-private-rt"
  })
}

# Route Table assosiations

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}