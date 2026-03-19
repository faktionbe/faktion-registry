# ECS Cluster Module - Shared across multiple services
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-sw-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# IAM Role for ECS Task Execution (shared across services)
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Role Policy Attachment for ECS Task Execution
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Policy for Secrets Manager access (execution role needs this to pull secrets during startup)
resource "aws_iam_policy" "execution_secrets_access" {
  name        = "${var.project_name}-${var.environment}-execution-secrets-access"
  description = "Policy to allow ECS execution role to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:*:secret:${var.project_name}/${var.environment}/*"
        ]
      }
    ]
  })
}

# Attach the secrets policy to the ECS execution role
resource "aws_iam_role_policy_attachment" "execution_secrets_access" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.execution_secrets_access.arn
}

