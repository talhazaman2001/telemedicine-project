# S3 Bucket to store CodePipeline Artifacts
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "codepipeline-artifacts-talhazaman"
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

resource "aws_iam_role_policy_attachment" "codestar_attach" {
    role = aws_iam_role.codepipeline_role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSCodestarFullAccess"
}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codebuild.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

# IAM Role for CodeDeploy
resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codedeploy.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForECS"
}

# Create CodeBuild Project
resource "aws_codebuild_project" "telemedicine_backend_build" {
  name = "telemedicine-backend-build"

  source {
    type      = "GITHUB"
    location  = "https://github.com/talhazaman2001/telemedicine-project.git"
    buildspec = "buildspec.yml"
  }

  artifacts {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_artifacts.bucket
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  service_role = aws_iam_role.codebuild_role.arn
}

# Create CodeDeploy Application for Fargate deployment
resource "aws_codedeploy_app" "telemedicine_codedeploy_app" {
  name             = "telemedicine-app"
  compute_platform = "ECS"
}

# Blue-Green deployment for all 3 ECS services
# Patient Data Service
resource "aws_codedeploy_deployment_group" "patient_data_codedeploy_group" {
  app_name               = aws_codedeploy_app.telemedicine_codedeploy_app.name
  deployment_group_name  = "patient-data-blue-green-deployment-group"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  auto_rollback_configuration {
    enabled = true
    events = ["DEPLOYMENT_FAILURE"]
  }
  
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.telemedicine_cluster.name
    service_name = aws_ecs_service.patient_data_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group.patient_data_blue_tg.name
      }

      target_group {
        name = aws_lb_target_group.patient_data_green_tg.name
      }

      prod_traffic_route {
        listener_arns = [aws_lb_listener.ecs_listener.arn]
      }
    }
  }
}

# Doctor Scheduling Service
resource "aws_codedeploy_deployment_group" "doctor_scheduling_codedeploy_group" {
  app_name               = aws_codedeploy_app.telemedicine_codedeploy_app.name
  deployment_group_name  = "doctor-scheduling-blue-green-deployment-group"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  auto_rollback_configuration {
    enabled = true
    events = ["DEPLOYMENT_FAILURE"]
  }
  
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.telemedicine_cluster.name
    service_name = aws_ecs_service.doctor_scheduling_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group.doctor_scheduling_blue_tg.name
      }

      target_group {
        name = aws_lb_target_group.doctor_scheduling_green_tg.name
      }

      prod_traffic_route {
        listener_arns = [aws_lb_listener.ecs_listener.arn]
      }
    }
  }
}

# Health Monitoring Service
resource "aws_codedeploy_deployment_group" "health_monitoring_codedeploy_group" {
  app_name               = aws_codedeploy_app.telemedicine_codedeploy_app.name
  deployment_group_name  = "health-monitoring-blue-green-deployment-group"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  auto_rollback_configuration {
    enabled = true
    events = ["DEPLOYMENT_FAILURE"]
  }
  
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.telemedicine_cluster.name
    service_name = aws_ecs_service.health_monitoring_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group.health_monitoring_blue_tg.name
      }

      target_group {
        name = aws_lb_target_group.health_monitoring_green_tg.name
      }

      prod_traffic_route {
        listener_arns = [aws_lb_listener.ecs_listener.arn]
      }
    }
  }
}


# CodePipeline to automate entire deployment process
resource "aws_codepipeline" "telmedicine_pipeline" {
  name     = "telemedicine-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_artifacts.bucket
  }

  stage {
    name = "Source"
    action {
      name             = "GitHubSource"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]
      configuration = {
        ConnectionArn = "arn:aws:codestar-connections:eu-west-2:463470963000:connection/43c0e9a0-f3d6-4d89-9645-5044376ab9f4"
        FullRepositoryId = "talhazaman2001/telemedicine-project"
        BranchName     = "main"
      }

    }
  }

  stage {
    name = "Build"
    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      configuration = {
        ProjectName = "${aws_codebuild_project.telemedicine_backend_build.name}"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "DeployPatientDataService"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["BuildOutput"]
      configuration = {
        ApplicationName     = "${aws_codedeploy_app.telemedicine_codedeploy_app.name}"
        DeploymentGroupName = "${aws_codedeploy_deployment_group.patient_data_codedeploy_group.deployment_group_name}"
      }
    }

    action {
      name = "DeployDoctorSchedulingService"
      category = "Deploy"
      owner = "AWS"
      provider = "CodeDeploy"
      version = "1"
      input_artifacts = ["BuildOutput"]
      configuration = {
        ApplicationName = "${aws_codedeploy_app.telemedicine_codedeploy_app.name}"
        DeploymentGroupName = "${aws_codedeploy_deployment_group.doctor_scheduling_codedeploy_group.deployment_group_name}"
      }
    }

    action {
      name = "DeployHealthMonitoringService"
      category = "Deploy"
      owner = "AWS"
      provider = "CodeDeploy"
      version = "1"
      input_artifacts = ["BuildOutput"]
      configuration = {
        ApplicationName = "${aws_codedeploy_app.telemedicine_codedeploy_app.name}"
        DeploymentGroupName = "${aws_codedeploy_deployment_group.health_monitoring_codedeploy_group.deployment_group_name}"
      }
    }
  }
}

# Create CodeStar Connection
resource "aws_codestarconnections_connection" "github_connection" {
    name = "my-github-connection"
    provider_type = "GitHub"
}
