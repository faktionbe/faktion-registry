# Create a placeholder zip file for initial deployment
data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/sqs-orchestrator-placeholder.zip"
  
  source {
    content = templatefile("${path.module}/placeholder-index.js", {})
    filename = "index.js"
  }
}

resource "aws_lambda_function" "sqs_orchestrator" {
  filename         = data.archive_file.lambda_placeholder.output_path
  function_name    = "${var.project_name}-${var.environment}-sqs-orchestrator"
  role            = aws_iam_role.lambda_execution.arn
  handler         = "index.handler"
  runtime         = "nodejs20.x"
  timeout         = 30
  memory_size     = 256
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  # Ignore changes to filename and source_code_hash as GitHub Actions will manage updates
  # This prevents Terraform from overwriting the Lambda code deployed by GitHub Actions
  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
  
  tags = var.tags
}

resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-${var.environment}-sqs-orchestrator-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name = "${var.project_name}-${var.environment}-sqs-orchestrator-sqs-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.source_queue_arn
      }
    ]
  })
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.source_queue_arn
  function_name    = aws_lambda_function.sqs_orchestrator.arn
  batch_size       = 10
  
  # Enable partial batch responses
  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.sqs_orchestrator.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
} 