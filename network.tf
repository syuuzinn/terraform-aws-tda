# ---------------------------------------------
# VPC
# ---------------------------------------------
resource "aws_vpc" "terra_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  tags = {
    Name = "basecamp-step1-vpc"
  }

}

# ---------------------------------------------
# internet Gateway
# ---------------------------------------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.terra_vpc.id

  tags = {
    Name = "basecamp-step1-igw"
  }
}

# ---------------------------------------------
# Public Subnet
# ---------------------------------------------
resource "aws_subnet" "terra_public_subnet1" {

  vpc_id            = aws_vpc.terra_vpc.id
  availability_zone = "ap-northeast-1a"

  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "basecamp-step1-public1"
  }

}

resource "aws_subnet" "terra_public_subnet2" {

  vpc_id            = aws_vpc.terra_vpc.id
  availability_zone = "ap-northeast-1c"

  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "basecamp-step1-public2"
  }

}

# ---------------------------------------------
# Route Table
# ---------------------------------------------
resource "aws_route_table" "terra_route_table" {
  vpc_id = aws_vpc.terra_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  #   route {
  #     cidr_block = "10.0.0.0/16"
  #     gateway_id = "local"
  #   }

  tags = {
    Name = "basecamp-step1-public-rtb"
  }
}

# ---------------------------------------------
# Private Subnet
# ---------------------------------------------
resource "aws_subnet" "terra_private_subnet1" {

  vpc_id            = aws_vpc.terra_vpc.id
  availability_zone = "ap-northeast-1a"

  cidr_block = "10.0.10.0/24"
  tags = {
    Name = "basecamp-step1-private1"
  }

}

resource "aws_subnet" "terra_private_subnet2" {

  vpc_id            = aws_vpc.terra_vpc.id
  availability_zone = "ap-northeast-1c"

  cidr_block = "10.0.11.0/24"
  tags = {
    Name = "basecamp-step1-private2"
  }

}