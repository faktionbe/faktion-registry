variable "s3_bucket_name" {
  description = "ID of the S3 bucket to apply the policy to"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket to apply the policy to"
  type        = string
}

variable "arns" {
  description = "List of ARNs for ML-related AWS principals to grant access to the S3 bucket"
  type        = list(string)
}
