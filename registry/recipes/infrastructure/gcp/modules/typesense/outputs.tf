output "internal_ip" {
  description = "Internal IP address of the Typesense VM (use this for Cloud Run connections)"
  value       = google_compute_instance.typesense.network_interface[0].network_ip
}

output "host" {
  description = "Typesense host (internal IP) for service connections"
  value       = google_compute_instance.typesense.network_interface[0].network_ip
}

output "port" {
  description = "Typesense port"
  value       = "8108"
}

output "service_account_email" {
  description = "Service account email used by Typesense VM"
  value       = google_service_account.typesense.email
}

output "instance_name" {
  description = "Name of the Typesense VM instance"
  value       = google_compute_instance.typesense.name
}

output "zone" {
  description = "Zone where the Typesense VM is deployed"
  value       = google_compute_instance.typesense.zone
}
