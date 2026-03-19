variable "project_id" {
  description = "GCP Project ID (not strictly required, but kept for consistency)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. development, staging, production)"
  type        = string
}

variable "secrets" {
  description = "Map of secret logical names to their plaintext values"
  type        = map(string)
}


