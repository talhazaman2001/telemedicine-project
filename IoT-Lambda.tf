# Iot Thing Creation
resource "aws_iot_thing" "iot_device" {
  name = "telemedicine-device"
  attributes = {
    device_type = "glucose_levels"
  }
}

# IoT Policy for Device Authentication
resource "aws_iot_policy" "iot_device_policy" {
  name = "iot-device-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iot:Connect",
          "iot:Subscribe",
          "iot:Publish",
          "iot:Receive"
        ],
        Resource = "*"
      }
    ]
  })
}

# IAM Role and Policy for IoT Core to invoke Lambda function
resource "aws_iam_role" "iot_invoke_lambda_role" {
  name = "iot-invoke-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "iot.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "iot_invoke_lambda_policy" {
  name = "iot-invoke-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = "${aws_lambda_function.process_glucose_levels.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "iot_lambda_policy_attach" {
  role       = aws_iam_role.iot_invoke_lambda_role.name
  policy_arn = aws_iam_policy.iot_invoke_lambda_policy.arn
}

# IAM Role for Lambda to interact with other AWS services
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Define policies to allow Lambda to write to DynamoDB and invoke Fargate
resource "aws_iam_policy" "lambda_dynamodb_fargate_policy" {
  name = "lambda-dynamodb-fargate-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        Resource = "${aws_dynamodb_table.glucose_levels_table.arn}"
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask",
          "ecs:StartTask"
        ],
        Resource = "${aws_ecs_task_definition.telemedicine_task.arn}"
      },
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = "${aws_iam_role.ecs_task_execution_role.arn}"
      }
    ]
  })
}

# Attach policies to IAM Role

# DynamoDB and Fargate policy
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_fargate_policy_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_fargate_policy.arn
}

# CloudWatch Logs policy
resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_policy_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# X-Ray policy
resource "aws_iam_role_policy_attachment" "lambda_xray_policy_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Define Lambda function for processing glucose levels from IoT devices
resource "aws_lambda_function" "process_glucose_levels" {
  function_name = "ProcessGlucoseLevels"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  tracing_config {
    mode = "Active"
  }

  # ZIP file containing the function code
  filename = "${path.module}/lambda-function.zip"

  source_code_hash = filebase64sha256("${path.module}/lambda-function.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.glucose_levels_table.name
    }
  }
}


