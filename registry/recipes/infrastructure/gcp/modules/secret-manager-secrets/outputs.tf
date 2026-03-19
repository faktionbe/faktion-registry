output "secret_ids" {
  description = "Map of logical secret names to Secret Manager resource names"
  value       = { for k, s in google_secret_manager_secret.secrets : k => s.name }
}


