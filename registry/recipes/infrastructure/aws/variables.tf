variable "environment" {
  description = "Environment name"
  type        = string
  default     = "qa"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "ml_arns" {
  description = "List of ARNs for ML-related AWS principals to grant access to the S3 bucket"
  type        = list(string)
  default     = []
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = ""
}

variable "custom_domain" {
  description = "Custom domain for the CloudFront distribution (e.g., qa.evals.faktion.ai)"
  type        = string
}

variable "custom_domain_certificate_arn" {
  description = "ARN of the ACM certificate in us-east-1 for the custom domain"
  type        = string
}

variable "custom_domain_api_certificate_arn" {
  description = "ARN of the ACM certificate in us-east-1 for the custom domain"
  type        = string
}

variable "rds_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.m7g.large"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for the RDS instance"
  type        = number
  default     = 20
}

variable "rds_storage_type" {
  description = "Storage type for the RDS instance"
  type        = string
  default     = "gp3"
}

variable "rds_backup_retention_period" {
  description = "Backup retention period for the RDS instance"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "Backup window for the RDS instance"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "Maintenance window for the RDS instance"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}

variable "rds_multi_az" {
  description = "Multi-AZ for the RDS instance"
  type        = bool
  default     = false
}

variable "rds_deletion_protection" {
  description = "Deletion protection for the RDS instance"
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot for the RDS instance"
  type        = bool
  default     = true
}

variable "s3_allow_local_access" {
  description = "Allow local access to the S3 bucket"
  type        = bool
  default     = true
}

variable "use_sqs_orchestrator" {
  description = "Use the SQS orchestrator"
  type        = bool
  default     = false
}

variable "local_dev_queues" {
  description = "List of SQS queue names to receive messages from"
  type        = list(string)
  default     = []
}

variable "request_queue_arn" {
  description = "SQS queue name to send messages to"
  type        = string
  default     = ""
}

variable "response_queue_arn" {
  description = "SQS queue name to receive messages from"
  type        = string
  default     = ""
}

variable "sqs_orchestrator_queue_arn" {
  description = "ARN of the SQS orchestrator queue"
  type        = string
  default     = ""
}

variable "ecs_task_min_count" {
  description = "Minimum number of tasks for auto scaling"
  type        = number
  default     = 1
}

variable "ecs_task_max_count" {
  description = "Maximum number of tasks for auto scaling"
  type        = number
  default     = 2
}


variable "ecs_enable_exec" {
  description = "Enable ECS Exec"
  type        = bool
  default     = false
}












