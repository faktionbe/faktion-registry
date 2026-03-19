# ECS Service Module - Reusable for multiple services
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  container_name = var.service_name
}

# IAM Role for ECS Task (service-specific)
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-${var.environment}-${var.service_name}-task-role"

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

# ECS Task Definition
resource "aws_ecs_task_definition" "service" {
  family                   = "${var.project_name}-${var.environment}-${var.service_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      secrets     = var.container_secrets
      environment = var.container_environment
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 0
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-${var.environment}-${var.service_name}"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  execution_role_arn = var.execution_role_arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  tags = var.tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "service" {
  name              = "/ecs/${var.project_name}-${var.environment}-${var.service_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "service" {
  name                   = "${var.project_name}-${var.environment}-${var.service_name}"
  cluster                = var.cluster_id
  task_definition        = aws_ecs_task_definition.service.arn
  desired_count          = var.service_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = var.enable_exec

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_groups
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = local.container_name
      container_port   = var.container_port
    }
  }

  tags = var.tags
}

# Add SSM permissions for ECS Exec
resource "aws_iam_policy" "ecs_exec" {
  count       = var.enable_exec ? 1 : 0
  name        = "${var.project_name}-${var.environment}-${var.service_name}-ecs-exec"
  description = "Policy to allow ECS Exec"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec" {
  count      = var.enable_exec ? 1 : 0
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_exec[0].arn
}

# IAM policies for secrets access (if secrets are provided)
resource "aws_iam_policy" "secrets_access" {
  count       = length(var.secret_manager_arns) > 0 ? 1 : 0
  name        = "${var.project_name}-${var.environment}-${var.service_name}-secrets-access"
  description = "Policy to allow ECS tasks to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secret_manager_arns
      }
    ]
  })
}

# Attach the secrets policy to the ECS task role
resource "aws_iam_role_policy_attachment" "secrets_access" {
  count      = length(var.secret_manager_arns) > 0 ? 1 : 0
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.secrets_access[0].arn
}



# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy - CPU
resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "${var.project_name}-${var.environment}-${var.service_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.autoscaling_cpu_target
  }
}

# Auto Scaling Policy - Memory
resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "${var.project_name}-${var.environment}-${var.service_name}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.autoscaling_memory_target
  }
}

# IAM Policy for S3 access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.project_name}-${var.environment}-${var.service_name}-s3-access"
  description = "Policy for ECS execution role to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-data",
          "arn:aws:s3:::${var.project_name}-${var.environment}-data/*",
          "arn:aws:s3:::${var.project_name}ml-${var.environment}-data",
          "arn:aws:s3:::${var.project_name}ml-${var.environment}-data/*"
        ]
      }
    ]
  })
}

# Attach the S3 access policy to the ECS execution role
resource "aws_iam_role_policy_attachment" "service_s3_access" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}




resource "aws_iam_policy" "sqs_access_policy" {
  name        = "${var.project_name}-${var.environment}-${var.service_name}-sqs-access"
  description = "Policy for ECS execution role to access SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl"
        ]
        Resource = var.request_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = var.response_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = [for name in var.local_dev_queues : "arn:aws:sqs:eu-west-1:018489564711:${var.project_name}-${var.environment}-${name}.fifo"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "service_sqs_access" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.sqs_access_policy.arn
}