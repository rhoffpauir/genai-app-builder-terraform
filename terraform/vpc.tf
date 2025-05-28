locals {
  cidr_block = "10.0.0.0/16"
  azs_count  = 2
}

# Create a VPC if needed
resource "aws_vpc" "vpc" {
  count = local.deploy_vpc_condition ? 1 : 0
  
  cidr_block           = local.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "DeploymentPlatformVPC-${random_string.random_suffix.result}"
  }
}

# Fetch available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create private subnets
resource "aws_subnet" "private" {
  count = local.deploy_vpc_condition ? local.azs_count : 0
  
  vpc_id            = aws_vpc.vpc[0].id
  cidr_block        = cidrsubnet(local.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "DeploymentPlatformPrivateSubnet${count.index + 1}-${random_string.random_suffix.result}"
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count = local.deploy_vpc_condition ? local.azs_count : 0
  
  vpc_id                  = aws_vpc.vpc[0].id
  cidr_block              = cidrsubnet(local.cidr_block, 8, count.index + local.azs_count)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "DeploymentPlatformPublicSubnet${count.index + 1}-${random_string.random_suffix.result}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  count = local.deploy_vpc_condition ? 1 : 0
  
  vpc_id = aws_vpc.vpc[0].id
  
  tags = {
    Name = "DeploymentPlatformIGW-${random_string.random_suffix.result}"
  }
}

# Create NAT Gateway
resource "aws_eip" "nat" {
  count = local.deploy_vpc_condition ? local.azs_count : 0
  
  domain = "vpc"
  
  tags = {
    Name = "DeploymentPlatformNATEIP${count.index + 1}-${random_string.random_suffix.result}"
  }
}

resource "aws_nat_gateway" "nat" {
  count = local.deploy_vpc_condition ? local.azs_count : 0
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  depends_on = [aws_internet_gateway.igw]
  
  tags = {
    Name = "DeploymentPlatformNATGateway${count.index + 1}-${random_string.random_suffix.result}"
  }
}

# Create route tables
resource "aws_route_table" "public" {
  count = local.deploy_vpc_condition ? 1 : 0
  
  vpc_id = aws_vpc.vpc[0].id
  
  tags = {
    Name = "DeploymentPlatformPublicRouteTable-${random_string.random_suffix.result}"
  }
}

resource "aws_route" "public_internet_gateway" {
  count = local.deploy_vpc_condition ? 1 : 0
  
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
}

resource "aws_route_table" "private" {
  count = local.deploy_vpc_condition ? local.azs_count : 0
  
  vpc_id = aws_vpc.vpc[0].id
  
  tags = {
    Name = "DeploymentPlatformPrivateRouteTable${count.index + 1}-${random_string.random_suffix.result}"
  }
}

resource "aws_route" "private_nat_gateway" {
  count = local.deploy_vpc_condition ? local.azs_count : 0
  
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

# Associate route tables with subnets
resource "aws_route_table_association" "public" {
  count = local.deploy_vpc_condition ? local.azs_count : 0
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count = local.deploy_vpc_condition ? local.azs_count : 0
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Create security groups
resource "aws_security_group" "lambda_sg" {
  count = local.deploy_vpc_condition ? 1 : 0
  
  name        = "DeploymentPlatformLambdaSG-${random_string.random_suffix.result}"
  description = "Security Group for Lambda functions"
  vpc_id      = aws_vpc.vpc[0].id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "DeploymentPlatformLambdaSG"
  }
}

# For conditional VPC configuration in Lambda functions and other resources
locals {
  # For Lambda configuration
  lambda_vpc_config = local.vpc_enabled_condition ? {
    subnet_ids = local.deploy_vpc_condition ? aws_subnet.private[*].id : var.existing_private_subnet_ids
    security_group_ids = local.deploy_vpc_condition ? [aws_security_group.lambda_sg[0].id] : var.existing_security_group_ids
  } : null
}
