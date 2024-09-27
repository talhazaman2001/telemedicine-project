# IAM Role for QuickSight to access DynamoDB and S3
resource "aws_iam_role" "quicksight_role" {
  name = "quicksight-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "quicksight.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Access to S3 and DynamoDB
resource "aws_iam_role_policy_attachment" "quicksight_s3_access" {
  role       = aws_iam_role.quicksight_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "quicksight_dynamodb_access" {
  role       = aws_iam_role.quicksight_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}
