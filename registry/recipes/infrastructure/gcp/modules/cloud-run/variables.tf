variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
}

variable "image" {
  description = "Container image URL"
  type        = string
}

variable "port" {
  description = "Container port"
  type        = number
  default     = 8080
}

variable "env_vars" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "secret_env_vars" {
  description = "Environment variables sourced from Secret Manager (name -> { secret, version })"
  type = map(object({
    secret  = string
    version = string
  }))
  default = {}
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "1"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "vpc_connector_id" {
  description = "VPC Access Connector ID (optional)"
  type        = string
  default     = null
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "enable_liveness_probe" {
  description = "Enable liveness probe (not needed for frontend services)"
  type        = bool
  default     = true
}

variable "allow_public_access" {
  description = "Allow public access (allUsers)"
  type        = bool
  default     = true
}

variable "service_account_email" {
  description = "Service account email to run the Cloud Run service as"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection for the Cloud Run service"
  type        = bool
  default     = false
}
