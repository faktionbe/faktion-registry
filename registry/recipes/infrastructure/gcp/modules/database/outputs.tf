output "instance_name" {
  description = "Database instance name"
  value       = google_sql_database_instance.postgres.name
}

output "connection_name" {
  description = "Database connection name"
  value       = google_sql_database_instance.postgres.connection_name
}

output "private_ip_address" {
  description = "Private IP address"
  value       = google_sql_database_instance.postgres.private_ip_address
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = google_sql_database.database.name
}
