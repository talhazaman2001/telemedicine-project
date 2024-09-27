# Define the ECS cluster
resource "aws_ecs_cluster" "telemedicine_cluster" {
  name = "telemedicine-cluster"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Attach ECS Task Policy to IAM Role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach X-Ray Policy to write to ECS
resource "aws_iam_role_policy_attachment" "ecs_task_xray_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Attach CloudWatch Policy to log ECS
resource "aws_iam_role_policy_attachment" "ecs_task_cloudwatch_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# Attach DynamoDB Policy to read from ECS
resource "aws_iam_role_policy_attachment" "ecs_task_dynamodb_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}

# Attach RDS Policy to read from ECS
resource "aws_iam_role_policy_attachment" "ecs_task_rds_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

# ECS Task Definition for Dockerised Microservices
resource "aws_ecs_task_definition" "telemedicine_task" {
  family                   = "telemedicine-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"

  container_definitions = jsonencode([
    {
      name = "xray-daemon"
      image = "amazon/aws-xray-daemon"
      essential = false
      memory = 512
      cpu = 256
      portMappings = [{
        containerPort = 2000
        protocol = "udp"
      }]
    },
    {
      name      = "patient-data-service"
      image     = "${aws_ecr_repository.patient_data_service.repository_url}:latest" # Use ECR URI from output in ECR file
      essential = true
      portMappings = [{
        containerPort = 5000
        hostPort      = 5000
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs-patient-data"
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      dependsOn = [{
        condition      = "START"
        ContainerName = "xray-daemon"
      }]
    },
    {
      name      = "doctor-scheduling-service"
      image     = "${aws_ecr_repository.doctor_scheduling_service.repository_url}:latest" # Use ECR URI from output in ECR file
      essential = true
      portMappings = [{
        containerPort = 5001
        hostPort      = 5001
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/doctor-scheduling"
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      dependsOn = [{
        condition      = "START"
        ContainerName = "xray-daemon"
      }]
    },
    {
      name      = "health-monitoring-service"
      image     = "${aws_ecr_repository.health_monitoring_service.repository_url}:latest" # Use ECR URI from output in ECR file
      essential = true
      portMappings = [{
        containerPort = 5002
        hostPort      = 5002
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/health-monitoring-service"
          "awslogs-region"        = "eu-west-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      dependsOn = [{
        condition      = "START"
        ContainerName = "xray-daemon"
      }]
    },
  ])
}

# ECS Security Group
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main_vpc.id
  name   = "ecs-service-sg"
}

# Define the 3 ECS services 
resource "aws_ecs_service" "patient_data_service" {
  name            = "patient-data-service"
  cluster         = aws_ecs_cluster.telemedicine_cluster.id
  task_definition = aws_ecs_task_definition.telemedicine_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  # Load balancer for patient-data-service
  load_balancer {
    target_group_arn = aws_lb_target_group.patient_data_blue_tg.arn
    container_name   = "patient-data-service"
    container_port   = 5000
  }

  network_configuration {
    subnets          = aws_subnet.private_subnets[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "doctor_scheduling_service" {
  name            = "doctor-scheduling-service"
  cluster         = aws_ecs_cluster.telemedicine_cluster.id
  task_definition = aws_ecs_task_definition.telemedicine_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.doctor_scheduling_blue_tg.arn
    container_name   = "doctor-scheduling-service"
    container_port   = 5001
  }

  network_configuration {
    subnets          = aws_subnet.private_subnets[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
}

resource "aws_ecs_service" "health_monitoring_service" {
  name            = "health-monitoring-service"
  cluster         = aws_ecs_cluster.telemedicine_cluster.id
  task_definition = aws_ecs_task_definition.telemedicine_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.health_monitoring_blue_tg.arn
    container_name   = "health-monitoring-service"
    container_port   = 5002
  }

  network_configuration {
    subnets          = aws_subnet.private_subnets[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
}


