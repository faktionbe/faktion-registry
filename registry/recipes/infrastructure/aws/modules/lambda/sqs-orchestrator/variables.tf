variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "source_queue_arn" {
  description = "ARN of the source SQS queue (ml-response queue)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "queue_visibility_timeout_seconds" {
  description = "Visibility timeout for the SQS queue"
  type        = number
  default     = 300
}

variable "queue_message_retention_seconds" {
  description = "Message retention period for the SQS queue"
  type        = number
  default     = 1209600 # 14 days
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 

