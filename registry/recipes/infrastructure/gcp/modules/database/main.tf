# Cloud SQL PostgreSQL Instance
resource "google_sql_database_instance" "postgres" {
  name             = "${var.resource_name_prefix}-postgres-${var.environment}"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier              = var.db_tier
    availability_type = var.db_availability_type
    disk_size         = var.db_disk_size_gb
    disk_type         = "PD_SSD"

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = var.db_pitr_enabled
      transaction_log_retention_days = var.db_transaction_log_retention_days
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_id
    }

    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 1024
      record_application_tags = true
    }
  }

  deletion_protection = var.deletion_protection
}

# Database
resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.postgres.name
}

# Dedicated application DB user.
# We intentionally do NOT manage the built-in `postgres` Cloud SQL superuser in Terraform,
# because (a) it typically owns most objects in a real database and (b) deleting it during
# updates/teardown often fails (and can be unsafe).
resource "google_sql_user" "app_user" {
  name     = var.db_user
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}
