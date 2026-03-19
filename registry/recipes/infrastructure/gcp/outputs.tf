output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "vpc_network_name" {
  description = "VPC network name"
  value       = module.networking.vpc_name
}

output "postgres_connection_name" {
  description = "Cloud SQL connection name"
  value       = module.database.connection_name
}

output "postgres_private_ip" {
  description = "PostgreSQL private IP address"
  value       = module.database.private_ip_address
  sensitive   = true
}

output "redis_host" {
  description = "Redis host address"
  value       = module.redis.host
}

output "redis_port" {
  description = "Redis port"
  value       = module.redis.port
}

output "server_url" {
  description = "Server Cloud Run service URL"
  value       = module.cloud_run_server.service_url
}

output "ats_url" {
  description = "ATS Cloud Run service URL"
  value       = module.cloud_run_ats.service_url
}

output "candidate_portal_url" {
  description = "Candidate Portal Cloud Run service URL"
  value       = module.cloud_run_candidate_portal.service_url
}

output "employer_portal_url" {
  description = "Employer Portal Cloud Run service URL"
  value       = module.cloud_run_employer_portal.service_url
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}"
}

output "typesense_internal_ip" {
  description = "Typesense VM internal IP address (for Cloud Run connections)"
  value       = module.typesense.internal_ip
}

output "typesense_instance_name" {
  description = "Typesense VM instance name"
  value       = module.typesense.instance_name
}

output "typesense_zone" {
  description = "Typesense VM zone"
  value       = module.typesense.zone
}

output "load_balancer_ip" {
  description = "Global Load Balancer IP address. Point your DNS A records to this IP."
  value       = var.enable_load_balancer && length(google_compute_global_address.lb_ip) > 0 ? google_compute_global_address.lb_ip[0].address : null
}

output "load_balancer_domains" {
  description = "Custom domains configured for the load balancer"
  value = var.enable_load_balancer ? {
    server           = var.domain_server != "" ? var.domain_server : null
    ats              = var.domain_ats != "" ? var.domain_ats : null
    candidate_portal = var.domain_candidate_portal != "" ? var.domain_candidate_portal : null
    employer_portal  = var.domain_employer_portal != "" ? var.domain_employer_portal : null
  } : null
}

output "static_assets_bucket_name" {
  description = "Cloud Storage bucket name for static assets"
  value       = google_storage_bucket.static_assets.name
}

output "static_assets_bucket_url" {
  description = "Public URL for static assets (use: https://storage.googleapis.com/BUCKET_NAME/path/to/asset)"
  value       = "https://storage.googleapis.com/${google_storage_bucket.static_assets.name}"
}
