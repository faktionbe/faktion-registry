output "rds_instance_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "rds_instance_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.main.address
}

output "rds_instance_port" {
  description = "The port on which the RDS instance accepts connections"
  value       = aws_db_instance.main.port
}

output "rds_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "rds_security_group_id" {
  description = "The ID of the security group for the RDS instance"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "rds_db_username" {
  description = "The username for the RDS instance"
  value       = var.db_username
  sensitive   = true
}

output "rds_db_password" {
  description = "The password for the RDS instance"
  value       = var.db_password
  sensitive   = true
}

output "rds_db_name" {
  description = "The name of the RDS instance"
  value       = var.db_name
}

output "rds_db_port" {
  description = "The port for the RDS instance"
  value       = aws_db_instance.main.port
}

output "rds_instance_identifier" {
  description = "The identifier for the RDS instance"
  value       = aws_db_instance.main.identifier
}






