output "queue_id" {
  value       = var.is_fifo ? (length(aws_sqs_queue.fifo) > 0 ? aws_sqs_queue.fifo[0].id : null) : (length(aws_sqs_queue.main) > 0 ? aws_sqs_queue.main[0].id : null)
  description = "The URL for the created Amazon SQS queue"
}

output "queue_arn" {
  value       = var.is_fifo ? (length(aws_sqs_queue.fifo) > 0 ? aws_sqs_queue.fifo[0].arn : null) : (length(aws_sqs_queue.main) > 0 ? aws_sqs_queue.main[0].arn : null)
  description = "The ARN of the SQS queue"
}

output "queue_name" {
  value       = var.is_fifo ? (length(aws_sqs_queue.fifo) > 0 ? aws_sqs_queue.fifo[0].name : null) : (length(aws_sqs_queue.main) > 0 ? aws_sqs_queue.main[0].name : null)
  description = "The name of the SQS queue"
}

output "queue_url" {
  value       = var.is_fifo ? (length(aws_sqs_queue.fifo) > 0 ? aws_sqs_queue.fifo[0].url : null) : (length(aws_sqs_queue.main) > 0 ? aws_sqs_queue.main[0].url : null)
  description = "The URL for the created Amazon SQS queue"
}

output "dead_letter_queue_id" {
  value       = var.enable_dead_letter_queue ? (var.is_fifo ? (length(aws_sqs_queue.fifo_dead_letter) > 0 ? aws_sqs_queue.fifo_dead_letter[0].id : null) : (length(aws_sqs_queue.dead_letter) > 0 ? aws_sqs_queue.dead_letter[0].id : null)) : null
  description = "The URL for the dead letter queue"
}

output "dead_letter_queue_arn" {
  value       = var.enable_dead_letter_queue ? (var.is_fifo ? (length(aws_sqs_queue.fifo_dead_letter) > 0 ? aws_sqs_queue.fifo_dead_letter[0].arn : null) : (length(aws_sqs_queue.dead_letter) > 0 ? aws_sqs_queue.dead_letter[0].arn : null)) : null
  description = "The ARN of the dead letter queue"
}

output "dead_letter_queue_name" {
  value       = var.enable_dead_letter_queue ? (var.is_fifo ? (length(aws_sqs_queue.fifo_dead_letter) > 0 ? aws_sqs_queue.fifo_dead_letter[0].name : null) : (length(aws_sqs_queue.dead_letter) > 0 ? aws_sqs_queue.dead_letter[0].name : null)) : null
  description = "The name of the dead letter queue"
} 