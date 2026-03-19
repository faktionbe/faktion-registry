# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.resource_name_prefix}-vpc-${var.environment}"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.resource_name_prefix}-subnet-${var.environment}"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc.id
  region        = var.region
}

# Private Service Connection for Cloud SQL
resource "google_compute_global_address" "private_ip" {
  name          = "${var.resource_name_prefix}-private-ip-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# VPC Access Connector for Cloud Run
resource "google_vpc_access_connector" "connector" {
  name          = "vpc-conn-${var.environment}"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.8.0.0/28"

  # Required: specify either throughput or instance scaling settings.
  # Values are passed from root via variables so they can be set per-environment in terraform.tfvars.
  min_throughput = var.vpc_connector_min_throughput
  max_throughput = var.vpc_connector_max_throughput
}

# Cloud Router (required for Cloud NAT)
resource "google_compute_router" "router" {
  name    = "${var.resource_name_prefix}-router-${var.environment}"
  region  = var.region
  network = google_compute_network.vpc.id
}

# Cloud NAT - allows VMs without external IPs to access the internet (e.g., pull Docker images)
resource "google_compute_router_nat" "nat" {
  name                               = "${var.resource_name_prefix}-nat-${var.environment}"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
