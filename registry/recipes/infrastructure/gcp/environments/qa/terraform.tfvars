project_id = "your-gcp-project-id" # Replace with your GCP project ID
region      = "europe-west1"
environment = "development"

# Database
db_tier          = "db-f1-micro" # Smallest tier (~25 max connections)
db_pool_size     = 5             # TypeORM pool per instance
pgboss_pool_size = 2             # pg-boss pool per instance
# NOTE: db_user and db_password are passed via GitHub Secrets (-var flags) or prompted when applying terraform.

# Cloud SQL settings
db_availability_type              = "ZONAL"
db_disk_size_gb                   = 20
db_pitr_enabled                   = false
db_transaction_log_retention_days = 3

# Cloud Run scaling
cloud_run_min_instances = 0 # No warm instances to avoid cold starts

# Protection
enable_deletion_protection = false

# VPC Access Connector throughput (Mbps)
vpc_connector_min_throughput = 200
vpc_connector_max_throughput = 300

# Redis
redis_tier           = "BASIC"
redis_memory_size_gb = 1

# Timezone
timezone = "UTC"

# Auth
access_token_lifetime = "1h"

# Typesense (GCE VM)
# NOTE: typesense_api_key is passed via GitHub Secrets (-var flag)
typesense_version      = "27.0" # Latest stable version
typesense_zone         = "europe-west1-b"
typesense_machine_type = "e2-small" # 2 vCPU, 2GB RAM - sufficient for dev
typesense_disk_size_gb = 20
typesense_disk_type    = "pd-balanced"

# =============================================================================
# Load Balancer & Custom Domains
# =============================================================================
# Set enable_load_balancer = true and configure domains to use custom domains.
# After applying, point your DNS A records to the load_balancer_ip output.
#
enable_load_balancer    = true
domain_server           = "dev.api.example.com"
domain_ats              = "dev.workspace.example.com"
domain_candidate_portal = "dev.account.example.com"
domain_employer_portal  = "dev.employer.example.com"

