
# VPC for k8s cluster lab
resource "aws_vpc" "k8s_vpc" {
  cidr_block           = var.vpc_k8s
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "k8s-vpc" }
}

# Internet gateway for NAT gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags   = { Name = "k8s-igw" }
}

# Public subnet -- holds the NAT gateway
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "172.16.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "public-subnet-a" }
}

# Public route table: default route to the IGW 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags   = { Name = "k8s-public-rt" }
}

# Route for public route table
resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Connects public route table with public subnet A
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# EIP for NAT gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = { Name = "EIP-NAT" }
}

# Nat gateway for private subnets
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id # NAT lives in a PUBLIC subnet
  depends_on    = [aws_internet_gateway.igw]

  tags = { Name = "NAT-gateway" }
}


# -----------------Private networking section----------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags   = { Name = "k8s-private-rt" }
}

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}


# Private subnet A 
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_route_table_association" "private_subnet_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# Private subnet B
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = "172.16.20.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "private-subnet-b"
  }
}

resource "aws_route_table_association" "private_subnet_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}




