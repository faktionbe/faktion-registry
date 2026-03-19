output "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "ecs_tasks_sqs_security_group_id" {
  description = "ID of the ECS tasks SQS security group"
  value       = aws_security_group.ecs_tasks_sqs.id
}

output "redis_security_group_id" {
  description = "ID of the Redis security group"
  value       = aws_security_group.redis.id
}