# Assign IAM Roles to access RDS and DynamoDB
resource "aws_iam_role" "sagemaker_execution_role" {
  name = "sagemaker-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "sagemaker.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "sagemaker_rds_dynamodb_policy" {
  name = "sagemaker-rds-dynamodb-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodn:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ],
        Resource = "${aws_dynamodb_table.glucose_levels_table.arn}"
      },
      {
        Effect = "Allow",
        Action = [
          "rds:DescribeDBInstances",
          "rds:Connect"
        ],
        Resource = "${aws_db_instance.telemedicine_rds.arn}"
      },
      {
        Effect   = "Allow",
        Action   = "rds-db:connect",
        Resource = "arn:aws:rds-db:eu-west-2:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.telemedicine_rds.id}/admin"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_rds_dynamodb_policy_attach" {
  role       = aws_iam_role.sagemaker_execution_role.name
  policy_arn = aws_iam_policy.sagemaker_rds_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "sagemaker_cloudwatch_logging" {
  role = aws_iam_role.sagemaker_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess" 
}

# IAM Policy for Sagemaker to access S3 Bucket to read datasets, write model artifacts, and retrieve training results
resource "aws_iam_policy" "sagemaker_execution_s3_access_policy" {
  name = "sagemaker-s3-access-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.sagemaker_bucket.bucket}/*", # Access objects
          "arn:aws:s3:::${aws_s3_bucket.sagemaker_bucket.bucket}"    # List bucket
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_policy_attach" {
  role       = aws_iam_role.sagemaker_execution_role.name
  policy_arn = aws_iam_policy.sagemaker_execution_s3_access_policy.arn
}

# Create SageMaker Notebook Instance
resource "aws_sagemaker_notebook_instance" "sagemaker_notebook" {
  name                  = "telemedicine-notebook"
  instance_type         = "ml.t2.medium"
  role_arn              = aws_iam_role.sagemaker_execution_role.arn
  lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_configuration.notebook_lifecycle.name

  tags = {
    Name = "Telemedicine Sagemaker Notebook"
  }
}

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "notebook_lifecycle" {
  name = "notebook-lifecycle"

  on_create = base64encode(<<LIFECYCLE
#!/bin/bash
echo "Notebook instance created on $(date)" >> /home/ec2-user/SageMaker/instance_log.txt
LIFECYCLE
  )

  on_start = base64encode(<<LIFECYCLE
#!/bin/bash
echo "Notebook instance started on $(date)" >> /home/ec2-user/SageMaker/notebook_startup_log.txt
mkdir -p /home/ec2-user/SageMaker/telemedicine
# Set up environment variables for the telemedicine project
export TELEMEDICINE_PROJECT='active'

# Navigate to the working directory
cd /home/ec2-user/SageMaker/telemedicine
LIFECYCLE
  )
}

# IAM Role for SageMaker Notebook Instance
resource "aws_iam_role_policy_attachment" "sagemaker_policy_attachment" {
  role       = aws_iam_role.sagemaker_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}
