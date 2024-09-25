# ECR repositories creation
resource "aws_ecr_repository" "patient_data_service" {
  name = "patient-data-service"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "doctor_scheduling_service" {
  name = "doctor-scheduling-service"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "health_monitoring_service" {
  name = "health-monitoring-service"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Add outputs for repository URIs for the ECS tasks to use
output "patient_data_service_ecr_uri" {
  value = aws_ecr_repository.patient_data_service.repository_url
}

output "doctor_scheduling_service_ecr_uri" {
  value = aws_ecr_repository.doctor_scheduling_service.repository_url
}

output "health_monitoring_service_ecr_uri" {
  value = aws_ecr_repository.health_monitoring_service.repository_url
}
