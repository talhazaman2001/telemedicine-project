# S3 Bucket for Training Data and Model Artifacts
resource "aws_s3_bucket" "sagemaker_bucket" {
  bucket = "telemedicine-sagemaker-bucket-talha"
}

# Lifecycle Rule for Training Data and Model Artifacts
resource "aws_s3_bucket_lifecycle_configuration" "telemedicine_sagemaker_config" {
  bucket = aws_s3_bucket.sagemaker_bucket.id

  rule {
    id = "telemedicine-sagemaker-archiving"

    expiration {
      days = 365
    }

    filter {
      and {
        prefix = "training-data-and-artifacts/"
        tags = {
          archive  = "true"
          datalife = "long"
        }
      }
    }

    status = "Enabled"

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }
  }
}

# S3 Versioning Bucket
resource "aws_s3_bucket" "telemedicine_sagemaker_versioning_bucket" {
  bucket = "telemedicine-sagemaker-versioning-bucket-talha"
}


# Enable S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "telemedicine_sagemaker_versioning" {
  bucket = aws_s3_bucket.sagemaker_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Versioning Lifecycle Rule for Training Data and Model Artifacts
resource "aws_s3_bucket_lifecycle_configuration" "telemedicine_sagemaker_versioning_bucket_config" {
  bucket = aws_s3_bucket.telemedicine_sagemaker_versioning_bucket.id

  rule {
    id = "telemedicine-sagemaker-versioning-bucket-config"

    filter {
      prefix = "versioning-training-data-and-artifacts/"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "INTELLIGENT_TIERING"
    }

    noncurrent_version_transition {
      noncurrent_days = 180
      storage_class   = "GLACIER"
    }

    status = "Enabled"
  }
}


