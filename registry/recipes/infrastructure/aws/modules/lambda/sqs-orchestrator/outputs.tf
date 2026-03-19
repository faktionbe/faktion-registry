output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.sqs_orchestrator.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.sqs_orchestrator.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.name
} 

output "sqs_orchestrator_iam_role_arn" {
  description = "ARN of the SQS orchestrator IAM role"
  value       = aws_iam_role.lambda_execution.arn
}