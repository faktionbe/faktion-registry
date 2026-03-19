variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone for the VM (e.g. europe-west1-b)"
  type        = string
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet for the VM"
  type        = string
}

variable "allowed_source_ranges" {
  description = "CIDR ranges allowed to access Typesense (VPC Connector range + subnet range)"
  type        = list(string)
}

variable "typesense_api_key" {
  description = "API key for Typesense authentication"
  type        = string
  sensitive   = true
}

variable "typesense_version" {
  description = "Typesense Docker image version (e.g. 26.0, 27.0)"
  type        = string
}

variable "machine_type" {
  description = "GCE machine type for Typesense VM"
  type        = string
  default     = "e2-standard-2" # 2 vCPU, 8GB RAM - good starting point
}

variable "disk_type" {
  description = "Persistent disk type for Typesense data"
  type        = string
  default     = "pd-balanced" # Good balance of performance and cost
}

variable "disk_size_gb" {
  description = "Persistent disk size in GB for Typesense data"
  type        = number
  default     = 50
}

variable "deletion_protection" {
  description = "Enable deletion protection for the VM (recommended for production)"
  type        = bool
  default     = false
}
