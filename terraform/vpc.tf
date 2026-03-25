# vpc
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${local.common_name}-vpc"
  }
}

# IGW
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
    tags = {
    Name = "${local.common_name}-igw"
  }
}

# subnets
# Public subnet - ALB,NAT,Bastion
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
  tags ={
    Name = "${local.common_name}-public-subnet"
  }

}

# private subent - app EC2 , no internet

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = false
  tags = {
    Name = "${local.common_name}-private-subnet"
  }
}