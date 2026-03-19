# Basic service configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "service_name" {
  description = "Name of the service (e.g., server, worker, api)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# ECS cluster configuration
variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

# Task configuration
variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, etc.)"
  type        = string
}

variable "task_memory" {
  description = "Memory for the task in MB (512, 1024, 2048, etc.)"
  type        = string
}

variable "container_port" {
  description = "Port that the container listens on"
  type        = number
}

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

# Networking configuration
variable "subnet_ids" {
  description = "List of subnet IDs where the service will run"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the task"
  type        = bool
  default     = false
}

# Load balancer configuration (optional)
variable "target_group_arn" {
  description = "ALB target group ARN (optional)"
  type        = string
  default     = null
}

# Service configuration
variable "service_desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

# Container configuration
variable "container_secrets" {
  description = "List of secrets to inject into the container"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "container_environment" {
  description = "List of environment variables to inject into the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Logging configuration
variable "region" {
  description = "AWS region"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# IAM configuration
variable "secret_manager_arns" {
  description = "List of Secrets Manager ARNs the task needs access to"
  type        = list(string)
  default     = []
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks for auto-scaling"
  type        = number
  default     = 10
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization percentage for auto-scaling"
  type        = number
  default     = 70
}

variable "autoscaling_memory_target" {
  description = "Target memory utilization percentage for auto-scaling"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "enable_exec" {
  description = "Enable ECS Exec"
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