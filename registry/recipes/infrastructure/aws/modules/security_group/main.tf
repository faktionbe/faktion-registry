resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-${var.environment}-ecs-tasks-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.alb_backend_port
    to_port         = var.alb_backend_port
    protocol        = "tcp"
    security_groups = [var.alb_backend_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "ecs_tasks_sqs" {
  name        = "${var.project_name}-${var.environment}-ecs-tasks-sqs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.alb_sqs_port
    to_port         = var.alb_sqs_port
    protocol        = "tcp"
    security_groups = [var.alb_sqs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Security group for Redis"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}