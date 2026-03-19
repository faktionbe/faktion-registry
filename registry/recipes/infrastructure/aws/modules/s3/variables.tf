variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days after which noncurrent versions expire"
  type        = number
  default     = 30
}

variable "block_public_policy" {
  description = "Whether to block public bucket policies"
  type        = bool
}

variable "restrict_public_buckets" {
  description = "Whether to restrict public bucket access"
  type        = bool
}

variable "allow_local_access" {
  description = "Whether to allow local access to the bucket"
  type        = bool
  default     = false
}