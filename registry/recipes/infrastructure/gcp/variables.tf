variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "resource_name_prefix" {
  description = "Short lowercase prefix for GCP resource names (VPC, buckets, Cloud Run services, load balancer, etc.)."
  type        = string
  default     = "app"
}

variable "database_name" {
  description = "PostgreSQL database name on the Cloud SQL instance (used in connection URIs)."
  type        = string
  default     = "app"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west1"
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "The PostgreSQL password must be at least 8 characters long."
  }
}

variable "db_user" {
  description = "Application database user (do not use the built-in postgres superuser)"
  type        = string
  sensitive   = true
}

variable "vpc_connector_min_throughput" {
  description = "Minimum throughput (Mbps) for the VPC Access Connector"
  type        = number
  default     = 200
}

variable "vpc_connector_max_throughput" {
  description = "Maximum throughput (Mbps) for the VPC Access Connector"
  type        = number
  default     = 300
}

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_pool_size" {
  description = "TypeORM connection pool size (adjust based on db_tier max_connections)"
  type        = number
  default     = 10
}

variable "pgboss_pool_size" {
  description = "pg-boss connection pool size for job queue"
  type        = number
  default     = 3
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for critical resources"
  type        = bool
  default     = true
}

variable "redis_tier" {
  description = "Redis tier (e.g. BASIC, STANDARD_HA)"
  type        = string
  default     = "BASIC"
}

variable "redis_memory_size_gb" {
  description = "Redis memory size in GB"
  type        = number
  default     = 1
}

variable "db_availability_type" {
  description = "Cloud SQL availability type (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "db_disk_size_gb" {
  description = "Cloud SQL disk size in GB"
  type        = number
  default     = 20
}

variable "db_pitr_enabled" {
  description = "Enable point-in-time recovery for Cloud SQL"
  type        = bool
  default     = false
}

variable "db_transaction_log_retention_days" {
  description = "Cloud SQL transaction log retention days"
  type        = number
  default     = 3
}

variable "timezone" {
  description = "Timezone"
  type        = string
  default     = "UTZ"
}

variable "access_token_lifetime" {
  description = "Access token lifetime"
  type        = string
  default     = "1h"
}


variable "server_image_tag" {
  description = "Docker image tag for the Server app (e.g. a Git SHA or 'latest')."
  type        = string
  default     = "latest"
}

variable "ats_image_tag" {
  description = "Docker image tag for the ATS app (e.g. a Git SHA or 'latest')."
  type        = string
  default     = "latest"
}

variable "candidate_portal_image_tag" {
  description = "Docker image tag for the Candidate Portal app (e.g. a Git SHA or 'latest')."
  type        = string
  default     = "latest"
}

variable "employer_portal_image_tag" {
  description = "Docker image tag for the Employer Portal app (e.g. a Git SHA or 'latest')."
  type        = string
  default     = "latest"
}

variable "typesense_api_key" {
  description = "API key for Typesense authentication (minimum 32 characters recommended)"
  type        = string
  sensitive   = true
}

variable "typesense_version" {
  description = "Typesense Docker image version (e.g. 26.0, 27.0)"
  type        = string
}

variable "typesense_zone" {
  description = "GCP zone for the Typesense VM (should be in the same region)"
  type        = string
  default     = "europe-west1-b"
}

variable "typesense_machine_type" {
  description = "GCE machine type for Typesense VM"
  type        = string
  default     = "e2-standard-2" # 2 vCPU, 8GB RAM
}

variable "typesense_disk_size_gb" {
  description = "Persistent disk size in GB for Typesense data"
  type        = number
  default     = 50
}

variable "typesense_disk_type" {
  description = "Persistent disk type for Typesense data (pd-standard, pd-balanced, pd-ssd)"
  type        = string
  default     = "pd-balanced"
}

variable "enable_load_balancer" {
  description = "Enable Global HTTP(S) Load Balancer with managed SSL certificates for custom domains"
  type        = bool
  default     = false
}

variable "domain_server" {
  description = "Custom domain for the API server (e.g. api.example.com)"
  type        = string
}

variable "domain_ats" {
  description = "Custom domain for the ATS frontend (e.g. workspace.example.com)"
  type        = string
}

variable "domain_candidate_portal" {
  description = "Custom domain for the Candidate Portal (e.g. account.example.com)"
  type        = string
}

variable "domain_employer_portal" {
  description = "Custom domain for the Employer Portal (e.g. employer.example.com)"
  type        = string
}

variable "cloud_run_min_instances" {
  description = "Minimum number of Cloud Run instances (use 1 for production to avoid cold starts)"
  type        = number
  default     = 0
}
