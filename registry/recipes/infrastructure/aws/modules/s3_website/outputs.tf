output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.website.id
}

output "cloudfront_domain" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cloudfront_url" {
  description = "URL of the CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.id
} 