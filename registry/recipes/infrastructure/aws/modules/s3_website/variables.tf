variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "custom_domain" {
  description = "Custom domain for the CloudFront distribution (e.g., qa.evals.faktion.ai)"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate in us-east-1 for the custom domain"
  type        = string
  default     = null
}

