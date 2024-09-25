# VPC
resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "main-vpc"
    }
}

# Identify the CIDR ranges for the 3 Public Subnets
variable "public_subnet_cidrs" {
    type = list(string)
    description = "Public Subnet CIDR Values"
    default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

# Identify the CIDR ranges for the 3 Private Subnets
variable "private_subnet_cidrs" {
    type = list(string)
    description = "Private Subnet CIDR Values"
    default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

# Store the list of Availability Zones
variable "azs" {
    type = list(string)
    description = "Availability Zones"
    default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

# Public Subnets 
resource "aws_subnet" "public_subnets" {
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = element(var.public_subnet_cidrs, count.index)
    availability_zone = element(var.azs, count.index)
    tags = {
        Name = "Public Subnet ${count.index + 1}"
    }
}

# Private Subnets 
resource "aws_subnet" "private_subnets" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = element(var.private_subnet_cidrs, count.index)
    availability_zone = element(var.azs, count.index)
    tags = {
        Name = "Private Subnet ${count.index + 1}"
    }
}

# IGW for Public Subnets
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id
}

# Route Table for Public Subnets
resource "aws_route_table" "public_rt" {
   vpc_id = aws_vpc.main_vpc.id
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_rt_assoc" {
    count = 3
    subnet_id = aws_subnet.public_subnets[count.index].id
    route_table_id = aws_route_table.public_rt.id
}

# Add Route to Public Route Table (internet access)
resource "aws_route" "public_route" {
    route_table_id = aws_route_table.public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_eip" {
    count = 3
}

# NAT Gateways for Private Subnets
resource "aws_nat_gateway" "nat_gateway" {
    count = 3
    allocation_id = aws_eip.nat_eip[count.index].id
    subnet_id = aws_subnet.public_subnets[count.index].id
}

# Route Table for Private Subnets (use NAT Gateway)
resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.main_vpc.id
}

# Associate Route Table with Private Subnets
resource "aws_route_table_association" "private_rt-assoc" {
    count = 3
    subnet_id = aws_subnet.private_subnets[count.index].id
    route_table_id = aws_route_table.private_rt.id
}


# Add Route to Private Route Table
resource "aws_route" "private_route" {
    route_table_id = aws_route_table.private_rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[0].id
}

# Application Load Balancer in Public Subnets
resource "aws_lb" "ecs_alb" {
    name = "ecs-application-load-balancer"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb_sg.id]
    subnets = aws_subnet.public_subnets[*].id
    
    enable_deletion_protection = false

    tags = {
        Name = "ecs-application-load-balancer"
    }
}