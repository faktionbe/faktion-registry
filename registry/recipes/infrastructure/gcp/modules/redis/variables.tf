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

variable "resource_name_prefix" {
  description = "Prefix for Redis instance name"
  type        = string
}

variable "vpc_id" {
  description = "VPC network ID"
  type        = string
}

variable "redis_tier" {
  description = "Redis tier (e.g. BASIC, STANDARD_HA)"
  type        = string
}

variable "redis_memory_size_gb" {
  description = "Redis memory size in GB"
  type        = number
}
