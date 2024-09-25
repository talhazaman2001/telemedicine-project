# CloudWatch Log Group for Lambda logs
resource "aws_cloudwatch_log_group" "lambda_logs" {
    name = "/aws/lambda/${aws_lambda_function.process_glucose_levels.function_name}"

    retention_in_days = 28
}

# SNS Topic to trigger Lambda alerts
resource "aws_sns_topic" "lambda_alerts" {
    name = "lambda_alerts_topic"
}

# Create an SNS subscription 
resource "aws_sns_topic_subscription" "email_subscription" {
    topic_arn = aws_sns_topic.lambda_alerts.arn
    protocol = "email"
    endpoint = "mtalhazamanb@gmail.com"

}

# IAM Policy for Lambda to publish to SNS
resource "aws_iam_policy" "lambda_sns_policy" {
    name = "lambda_sns_policy"
    
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Action = "sns:Publish",
                Resource = aws_sns_topic.lambda_alerts.arn
            }
        ]
    })
}

# SNS publish policy
resource "aws_iam_role_policy_attachment" "lambda_sns_policy_attach" {
    role = aws_iam_role.lambda_execution_role.name
    policy_arn = aws_iam_policy.lambda_sns_policy.arn
}