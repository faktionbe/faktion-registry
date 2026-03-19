# Service account for Typesense VM
resource "google_service_account" "typesense" {
  account_id   = "typesense-${var.environment}"
  display_name = "Typesense VM service account (${var.environment})"
}

resource "google_project_iam_member" "typesense_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.typesense.email}"
}

resource "google_project_iam_member" "typesense_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.typesense.email}"
}

# Firewall: Allow Cloud Run (via VPC Connector) to talk to Typesense on port 8108
resource "google_compute_firewall" "allow_typesense_internal" {
  name    = "allow-typesense-internal-${var.environment}"
  network = var.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["8108"]
  }

  # Allow traffic from:
  # - VPC Connector range (Cloud Run egress)
  # - Subnet range (other VMs in the VPC)
  source_ranges = var.allowed_source_ranges
  target_tags   = ["typesense-server"]
}

# Firewall: Allow SSH via IAP for debugging/maintenance (optional but recommended)
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-typesense-iap-ssh-${var.environment}"
  network = var.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's IP range for TCP forwarding
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["typesense-server"]
}

# Persistent disk for Typesense data (survives VM recreation)
resource "google_compute_disk" "typesense_data" {
  name = "typesense-data-${var.environment}"
  type = var.disk_type
  zone = var.zone
  size = var.disk_size_gb

  labels = {
    environment = var.environment
    purpose     = "typesense-data"
  }
}

# Compute Engine Instance for Typesense
resource "google_compute_instance" "typesense" {
  name         = "typesense-${var.environment}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["typesense-server"]

  # Prevent accidental deletion in production
  deletion_protection = var.deletion_protection

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20 # Small boot disk, data goes to attached disk
      type  = "pd-balanced"
    }
  }

  # Attach the persistent data disk
  attached_disk {
    source      = google_compute_disk.typesense_data.self_link
    device_name = "typesense-data"
    mode        = "READ_WRITE"
  }

  network_interface {
    network    = var.vpc_name
    subnetwork = var.subnet_name

    # No external IP - traffic stays internal via Cloud NAT for outbound
    # Remove this block entirely if you need a public IP for debugging
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh", {
    typesense_api_key = var.typesense_api_key
    typesense_version = var.typesense_version
  })

  service_account {
    email  = google_service_account.typesense.email
    scopes = ["cloud-platform"]
  }

  labels = {
    environment = var.environment
    service     = "typesense"
  }

  # Allow stopping for updates
  allow_stopping_for_update = true
}
