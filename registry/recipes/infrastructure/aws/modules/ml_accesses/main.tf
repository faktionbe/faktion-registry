terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# S3 Bucket Policy for read/download accesses.
resource "aws_s3_bucket_policy" "ml_s3_read_access" {
  bucket = var.s3_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.arns
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetObjectVersion"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}