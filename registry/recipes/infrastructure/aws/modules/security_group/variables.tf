variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "alb_backend_security_group_id" {
  description = "ALB backend security group ID"
  type        = string
}

variable "alb_backend_port" {
  description = "ALB backend port"
  type        = number
}

variable "alb_sqs_security_group_id" {
  description = "ALB SQS security group ID"
  type        = string
}

variable "alb_sqs_port" {
  description = "ALB SQS port"
  type        = number
}
