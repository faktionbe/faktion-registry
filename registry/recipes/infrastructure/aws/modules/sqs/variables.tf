variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
}

variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Standard Queue Configuration
variable "delay_seconds" {
  description = "The time in seconds that the delivery of all messages in the queue will be delayed"
  type        = number
  default     = 0
}

variable "max_message_size" {
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it"
  type        = number
  default     = 262144
}

variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message"
  type        = number
  default     = 1209600 # 14 days
}

variable "receive_wait_time_seconds" {
  description = "The time for which a ReceiveMessage call will wait for a message to arrive"
  type        = number
  default     = 0
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue"
  type        = number
  default     = 30
}

# Dead Letter Queue Configuration
variable "enable_dead_letter_queue" {
  description = "Whether to create a dead letter queue"
  type        = bool
  default     = false
}

variable "max_receive_count" {
  description = "The number of times a message is delivered to the source queue before being moved to the dead-letter queue"
  type        = number
  default     = 3
}

variable "dlq_message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message in the dead letter queue"
  type        = number
  default     = 1209600 # 14 days
}

# FIFO Queue Configuration
variable "is_fifo" {
  description = "Whether to create a FIFO queue instead of a standard queue"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO queues"
  type        = bool
  default     = false
}

variable "deduplication_scope" {
  description = "Specifies whether message deduplication occurs at the message group or queue level"
  type        = string
  default     = "queue"

  validation {
    condition     = contains(["queue", "messageGroup"], var.deduplication_scope)
    error_message = "deduplication_scope must be either 'queue' or 'messageGroup'."
  }
}

variable "fifo_throughput_limit" {
  description = "Specifies whether the FIFO queue throughput quota applies to the entire queue or per message group"
  type        = string
  default     = "perQueue"

  validation {
    condition     = contains(["perQueue", "perMessageGroupId"], var.fifo_throughput_limit)
    error_message = "fifo_throughput_limit must be either 'perQueue' or 'perMessageGroupId'."
  }
}

# Encryption Configuration
variable "kms_master_key_id" {
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK"
  type        = string
  default     = null
}