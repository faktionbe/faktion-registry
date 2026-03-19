variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., qa, prod)"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "internal" {
  description = "Whether the ALB is internal or internet-facing"
  type        = bool
  default     = false
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "target_port" {
  description = "Port the target group forwards to"
  type        = number
  default     = 4000
}

variable "target_type" {
  description = "Type of target (instance or ip)"
  type        = string
  default     = "instance"
}

variable "health_check_healthy_threshold" {
  description = "Number of successful health checks before considering target healthy"
  type        = number
  default     = 2
}

variable "health_check_interval" {
  description = "Interval between health checks in seconds"
  type        = number
  default     = 30
}

variable "health_check_matcher" {
  description = "HTTP codes to use when checking for a healthy response"
  type        = string
  default     = "200"
}

variable "health_check_path" {
  description = "Path for the health check"
  type        = string
  default     = "/health"
}

variable "health_check_timeout" {
  description = "Timeout for health check in seconds"
  type        = number
  default     = 5
}

variable "health_check_unhealthy_threshold" {
  description = "Number of failed health checks before considering target unhealthy"
  type        = number
  default     = 2
}

variable "custom_domain" {
  description = "Custom domain for the ALB"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate in us-east-1 for the custom domain"
  type        = string
  default     = null
}

variable "idle_timeout" {
  description = "Idle timeout for the ALB"
  type        = number
  default     = 60
}
