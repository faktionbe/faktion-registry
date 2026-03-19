output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.subnet.name
}

output "vpc_connector_id" {
  description = "VPC Access Connector ID"
  value       = google_vpc_access_connector.connector.id
}

output "private_ip_range_name" {
  description = "Reserved peering range name for Private Service Access"
  value       = google_compute_global_address.private_ip.name
}

output "subnet_id" {
  description = "Subnet ID"
  value       = google_compute_subnetwork.subnet.id
}

output "vpc_connector_ip_cidr_range" {
  description = "VPC Access Connector IP CIDR range (Cloud Run egress IPs)"
  value       = google_vpc_access_connector.connector.ip_cidr_range
}
