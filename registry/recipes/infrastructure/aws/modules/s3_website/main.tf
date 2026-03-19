
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# S3 bucket for static website hosting
resource "aws_s3_bucket" "website" {
  bucket = "${var.project_name}-${var.environment}-website"

  tags = var.tags
}

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Configure server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudFront distribution for the S3 bucket
resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.website.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.website_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  aliases             = var.certificate_arn != null && var.certificate_arn != "" ? [var.custom_domain] : []
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Add custom error response for 404 to handle client-side routing
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  # Add custom error response for 403 to handle client-side routing
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.certificate_arn != null && var.certificate_arn != "" ? [1] : []
    content {
      acm_certificate_arn = var.certificate_arn
      ssl_support_method  = "sni-only"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.certificate_arn == null || var.certificate_arn == "" ? [1] : []
    content {
      cloudfront_default_certificate = true
    }
  }

  tags = var.tags
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "website_oai" {
  comment = "OAI for ${aws_s3_bucket.website.id}"
}

# S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudFrontAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.website_oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}