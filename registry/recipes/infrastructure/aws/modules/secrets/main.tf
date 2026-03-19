terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create the Secrets Manager secret
resource "aws_secretsmanager_secret" "credentials" {
  name = "${var.project_name}/${var.environment}/${var.secret_name}"
  tags = var.tags
}

# Create the secret version with ignore_changes if the flag is true
resource "aws_secretsmanager_secret_version" "credentials_with_ignore" {
  count         = var.ignore_secret_changes ? 1 : 0
  secret_id     = aws_secretsmanager_secret.credentials.id
  secret_string = var.secret_string

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Create the secret version without ignore_changes if the flag is false
resource "aws_secretsmanager_secret_version" "credentials_no_ignore" {
  count         = var.ignore_secret_changes ? 0 : 1
  secret_id     = aws_secretsmanager_secret.credentials.id
  secret_string = var.secret_string
}

# IAM policy to allow the ECS task to access the secrets
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-${var.environment}-${var.secret_name}-secrets-access"
  description = "Policy to allow ECS tasks to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = ["${aws_secretsmanager_secret.credentials.arn}*"]
      }
    ]
  })
}

