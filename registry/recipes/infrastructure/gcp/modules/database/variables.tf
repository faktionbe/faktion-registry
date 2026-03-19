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
  description = "Prefix for Cloud SQL instance name"
  type        = string
}

variable "database_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "vpc_id" {
  description = "VPC network ID"
  type        = string
}

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_user" {
  description = "Application database user (do not use the built-in postgres superuser)"
  type        = string
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "db_availability_type" {
  description = "Cloud SQL availability type (ZONAL or REGIONAL)"
  type        = string
}

variable "db_disk_size_gb" {
  description = "Cloud SQL disk size in GB"
  type        = number
}

variable "db_pitr_enabled" {
  description = "Enable point-in-time recovery for Cloud SQL"
  type        = bool
}

variable "db_transaction_log_retention_days" {
  description = "Cloud SQL transaction log retention days"
  type        = number
}
