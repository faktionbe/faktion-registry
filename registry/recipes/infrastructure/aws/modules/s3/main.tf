terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# S3 Bucket for application data
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.project_name}-${var.environment}-data"

  tags = var.tags
}

# Enable versioning for the bucket
resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Configure lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"

    filter {
      prefix = "" # Apply to all objects in the bucket
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = true
  restrict_public_buckets = var.restrict_public_buckets
}

# Bucket policy to allow access from the server and developers
resource "aws_s3_bucket_policy" "app_data" {
  count = var.allow_local_access ? 1 : 0

  bucket = aws_s3_bucket.app_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowDeveloperAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app_data.arn,
          "${aws_s3_bucket.app_data.arn}/*"
        ]
      }
    ]
  })
} 