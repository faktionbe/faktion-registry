output "host" {
  description = "Redis host address"
  value       = google_redis_instance.redis.host
}

output "port" {
  description = "Redis port"
  value       = google_redis_instance.redis.port
}

output "instance_name" {
  description = "Redis instance name"
  value       = google_redis_instance.redis.name
}
