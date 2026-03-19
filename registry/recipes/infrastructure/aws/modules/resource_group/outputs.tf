output "resource_group_name" {
  description = "Name of the created resource group"
  value       = aws_resourcegroups_group.environment_resources.name
}

output "resource_group_arn" {
  description = "ARN of the created resource group"
  value       = aws_resourcegroups_group.environment_resources.arn
}