terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# SQS Queue
resource "aws_sqs_queue" "main" {
  count = var.is_fifo ? 0 : 1

  name                       = "${var.project_name}-${var.environment}-${var.queue_name}"
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  kms_master_key_id          = var.kms_master_key_id

  # Configure dead letter queue if enabled
  redrive_policy = var.enable_dead_letter_queue ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = var.tags
}

# Dead Letter Queue (optional)
resource "aws_sqs_queue" "dead_letter" {
  count = var.enable_dead_letter_queue && !var.is_fifo ? 1 : 0

  name                      = "${var.project_name}-${var.environment}-${var.queue_name}-dlq"
  message_retention_seconds = var.dlq_message_retention_seconds
  kms_master_key_id         = var.kms_master_key_id

  tags = var.tags
}

# FIFO Queue (alternative to standard queue)
resource "aws_sqs_queue" "fifo" {
  count = var.is_fifo ? 1 : 0

  name                        = "${var.project_name}-${var.environment}-${var.queue_name}.fifo"
  fifo_queue                  = true
  content_based_deduplication = var.content_based_deduplication
  deduplication_scope         = var.deduplication_scope
  fifo_throughput_limit       = var.fifo_throughput_limit
  delay_seconds               = var.delay_seconds
  max_message_size            = var.max_message_size
  message_retention_seconds   = var.message_retention_seconds
  receive_wait_time_seconds   = var.receive_wait_time_seconds
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  kms_master_key_id           = var.kms_master_key_id

  # Configure dead letter queue if enabled
  redrive_policy = var.enable_dead_letter_queue ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.fifo_dead_letter[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = var.tags
}

# FIFO Dead Letter Queue (optional)
resource "aws_sqs_queue" "fifo_dead_letter" {
  count = var.is_fifo && var.enable_dead_letter_queue ? 1 : 0

  name                        = "${var.project_name}-${var.environment}-${var.queue_name}-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = var.content_based_deduplication
  message_retention_seconds   = var.dlq_message_retention_seconds
  kms_master_key_id           = var.kms_master_key_id

  tags = var.tags
}