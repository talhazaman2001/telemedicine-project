# DynamoDB to store Glucose levels data
resource "aws_dynamodb_table" "glucose_levels_table" {
    name = "GlucoseLevels"
    hash_key = "DeviceID"
    range_key = "Timestamp"
    billing_mode = "PAY_PER_REQUEST"

    attribute {
        name = "DeviceID"
        type = "S"
    }

    attribute {
      name = "Timestamp"
      type = "N"
    }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
    name = "rds_security_group"
    description = "Allow access to RDS"
    vpc_id = aws_vpc.main_vpc.id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"] # Allows internal VPC access
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "rds-sg"
    }
}

# Create RDS Subnet Group
resource "aws_db_subnet_group" "telemedicine_subnet_group" {
    name = "telemedicine-subnet-group"
    subnet_ids = [aws_subnet.private_subnets.id]

    tags = {
        Name = "Telemedicine RDS Subnet Group"
    }
}

# Launch RDS instance
resource "aws_db_instance" "telemedicine_rds" {
    allocated_storage = 20
    engine = "postgres"
    engine_version = "16.3"
    instance_class = "db.t3.micro"
    username = "admin"
    password = "password123"
    parameter_group_name = "default.postgres16"
    publicly_accessible = false
    vpc_security_group_ids = [aws_security_group.rds_sg.id]
    db_subnet_group_name = aws_db_subnet_group.telemedicine_subnet_group.name

    tags = {
        Name = "my-rds-instance"
    }

}

# Output the RDS endpoint
output "rds_endpoint" {
  value = aws_db_instance.telmedicine_rds.endpoint
}

