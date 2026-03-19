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

variable "secret_name" {
  description = "Name of the secret"
  type        = string
}

variable "secret_string" {
  description = "String to be encoded in the secret"
  type        = string
}

variable "ignore_secret_changes" {
  description = "Whether to ignore changes to secret values"
  type        = bool
  default     = false
}
