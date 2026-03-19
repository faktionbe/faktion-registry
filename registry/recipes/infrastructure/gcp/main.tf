terraform {
  # Backend configuration values (bucket, prefix, etc.) are provided per-environment
  # via backend config files in `infrastructure/environments/*/backend.hcl`.
  #
  # Example:
  #   terraform init -backend-config=environments/production/backend.hcl
  #   terraform init -backend-config=environments/development/backend.hcl
  backend "gcs" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.14.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "services" {
  for_each = toset([
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "monitoring.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "vpcaccess.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "cloud_run_server" {
  account_id   = "cloud-run-server-${var.environment}"
  display_name = "Cloud Run server service account (${var.environment})"

  depends_on = [google_project_service.services]
}

resource "google_service_account" "cloud_run_clients" {
  account_id   = "cloud-run-clients-${var.environment}"
  display_name = "Cloud Run clients service account (${var.environment})"

  depends_on = [google_project_service.services]
}

locals {
  cloud_run_service_account_emails = toset([
    google_service_account.cloud_run_server.email,
    google_service_account.cloud_run_clients.email,
  ])

  # Artifact Registry repository id (Docker). Must match image URLs below.
  artifact_registry_repository_id = "${var.resource_name_prefix}-images"
}

# IAM roles for Cloud Run service accounts
resource "google_project_iam_member" "cloud_run_artifact_registry" {
  for_each = local.cloud_run_service_account_emails

  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${each.value}"

  depends_on = [google_project_service.services]
}

resource "google_project_iam_member" "cloud_run_cloudsql" {
  for_each = local.cloud_run_service_account_emails

  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${each.value}"

  depends_on = [google_project_service.services]
}

resource "google_project_iam_member" "cloud_run_secretmanager" {
  for_each = local.cloud_run_service_account_emails

  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${each.value}"

  depends_on = [google_project_service.services]
}

# Make the bucket accessible to the Cloud Run "server" service account
resource "google_storage_bucket_iam_member" "cloud_run_server_admin" {
  bucket = google_storage_bucket.user_files.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_run_server.email}"

  depends_on = [google_project_service.services]
}

# Grants permission to cloud run server to create tokens for itself (required for signing bucket URLs)
resource "google_service_account_iam_member" "cloud_run_server_token_signing" {
  service_account_id = google_service_account.cloud_run_server.id
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.cloud_run_server.email}"

  depends_on = [google_project_service.services]
}

# IAM propagation delay:
# Cloud Run validates Secret Manager access at revision creation time, and IAM changes can take
# a short time to propagate. Without this, first-time deploys frequently fail with:
# "Permission denied on secret ... for Revision service account ..."
resource "terraform_data" "wait_for_cloud_run_iam_propagation" {
  input = {
    project_id    = var.project_id
    environment   = var.environment
    server_sa     = google_service_account.cloud_run_server.email
    clients_sa    = google_service_account.cloud_run_clients.email
    secret_role   = "roles/secretmanager.secretAccessor"
    sleep_seconds = 60
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }

  depends_on = [
    google_project_iam_member.cloud_run_artifact_registry,
    google_project_iam_member.cloud_run_cloudsql,
    google_project_iam_member.cloud_run_secretmanager,
  ]
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  project_id             = var.project_id
  region                 = var.region
  environment            = var.environment
  resource_name_prefix   = var.resource_name_prefix

  vpc_connector_min_throughput = var.vpc_connector_min_throughput
  vpc_connector_max_throughput = var.vpc_connector_max_throughput

  depends_on = [google_project_service.services]
}

# Private Service Access (Service Networking VPC peering) for Cloud SQL / Memorystore.
# Kept at root so producer services can explicitly depend on it, ensuring correct destroy order.
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.networking.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [module.networking.private_ip_range_name]
}

# Delay to allow GCP to fully release the VPC peering after Cloud SQL/Redis destruction.
# Create order: connection → time_sleep → database/redis
# Destroy order: database/redis → time_sleep (60s wait) → connection
resource "time_sleep" "wait_for_vpc_peering_cleanup" {
  create_duration  = "0s"
  destroy_duration = "60s"

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Database Module
module "database" {
  source = "./modules/database"

  project_id             = var.project_id
  region                 = var.region
  environment            = var.environment
  resource_name_prefix   = var.resource_name_prefix
  database_name          = var.database_name

  vpc_id = module.networking.vpc_id

  db_tier                           = var.db_tier
  db_password                       = var.db_password
  db_user                           = var.db_user
  deletion_protection               = var.enable_deletion_protection
  db_availability_type              = var.db_availability_type
  db_disk_size_gb                   = var.db_disk_size_gb
  db_pitr_enabled                   = var.db_pitr_enabled
  db_transaction_log_retention_days = var.db_transaction_log_retention_days

  # Depend on time_sleep to ensure correct destroy order:
  # database destroyed → 60s wait → VPC peering destroyed
  depends_on = [time_sleep.wait_for_vpc_peering_cleanup]
}

# Redis Module
module "redis" {
  source = "./modules/redis"

  project_id             = var.project_id
  region                 = var.region
  environment            = var.environment
  resource_name_prefix   = var.resource_name_prefix

  vpc_id               = module.networking.vpc_id
  redis_tier           = var.redis_tier
  redis_memory_size_gb = var.redis_memory_size_gb

  # Depend on time_sleep to ensure correct destroy order:
  # redis destroyed → 60s wait → VPC peering destroyed
  depends_on = [time_sleep.wait_for_vpc_peering_cleanup]
}

# Typesense Module (Self-hosted GCE instance)
module "typesense" {
  source = "./modules/typesense"

  project_id  = var.project_id
  region      = var.region
  zone        = var.typesense_zone
  environment = var.environment

  # Networking - use existing VPC
  vpc_name    = module.networking.vpc_name
  subnet_name = module.networking.subnet_name

  # Allow traffic from VPC Connector (Cloud Run egress) and the main subnet
  allowed_source_ranges = [
    module.networking.vpc_connector_ip_cidr_range, # Cloud Run egress IPs
    "10.0.0.0/24",                                 # Main subnet range
  ]

  # Typesense configuration
  typesense_api_key = var.typesense_api_key
  typesense_version = var.typesense_version

  # VM sizing
  machine_type = var.typesense_machine_type
  disk_size_gb = var.typesense_disk_size_gb
  disk_type    = var.typesense_disk_type

  # Protection
  deletion_protection = var.enable_deletion_protection

  depends_on = [
    google_project_service.services,
    module.networking
  ]
}

# Artifact Registry
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = local.artifact_registry_repository_id
  description   = "Docker images for application workloads"
  format        = "DOCKER"

  depends_on = [google_project_service.services]
}


# Public bucket for storing static assets (logos, images, etc.)
resource "google_storage_bucket" "static_assets" {
  name          = "${var.resource_name_prefix}-static-assets-${var.environment}"
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["Content-Type", "Cache-Control"]
    max_age_seconds = 3600
  }

  versioning {
    enabled = false
  }

  force_destroy = var.environment != "production"

  depends_on = [google_project_service.services]
}

# Make the bucket publicly readable
resource "google_storage_bucket_iam_member" "static_assets_public_read" {
  bucket = google_storage_bucket.static_assets.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Private bucket for storing user files
resource "google_storage_bucket" "user_files" {
  name          = "${var.resource_name_prefix}-user-files-${var.environment}"
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  cors {
    origin          = ["https://${var.domain_ats}"]
    method          = ["GET", "HEAD", "PUT", "OPTIONS"]
    response_header = ["Content-Type", "Cache-Control"]
    max_age_seconds = 3600
  }

  versioning {
    enabled = false
  }

  force_destroy = var.environment != "production"

  depends_on = [google_project_service.services]
}

locals {
  # Secrets are synced into GCP Secret Manager by `.github/workflows/sync-gcp-secrets.yml`.
  # We keep an explicit allowlist here so we only inject the secrets this service actually needs.
  cloud_run_server_secret_names = toset([
    "TYPESENSE_API_KEY",
    "JWT_SECRET",
    "GCP_BUCKET",
    "HUBSPOT_ACCESS_TOKEN",
    "HUBSPOT_SECRET",
    "HUBSPOT_TEST_VATNUMBERS",
    "HUBSPOT_TEST_EMAILS",
    "OPENAI_API_KEY",
    "PANDADOC_API_KEY",
    "POSTMARK_API_KEY",
    "SENTRY_DSN_SERVER"
  ])

  cloud_run_ats_secret_names = toset([
    "GOOGLE_API_KEY"
  ])

  cloud_run_candidate_portal_secret_names = toset([
    "GOOGLE_API_KEY",
    "SENTRY_DSN_CANDIDATE_PORTAL",
  ])
}

data "google_secret_manager_secret" "cloud_run_server" {
  for_each  = local.cloud_run_server_secret_names
  project   = var.project_id
  secret_id = each.key
}

data "google_secret_manager_secret" "cloud_run_ats" {
  for_each  = local.cloud_run_ats_secret_names
  project   = var.project_id
  secret_id = each.key
}

data "google_secret_manager_secret" "cloud_run_candidate_portal" {
  for_each  = local.cloud_run_candidate_portal_secret_names
  project   = var.project_id
  secret_id = each.key
}

locals {
  cloud_run_server_secret_env_vars = {
    for k, s in data.google_secret_manager_secret.cloud_run_server :
    k => {
      secret  = s.name
      version = "latest"
    }
  }

  cloud_run_ats_secret_env_vars = {
    for k, s in data.google_secret_manager_secret.cloud_run_ats :
    k => {
      secret  = s.name
      version = "latest"
    }
  }

  cloud_run_candidate_portal_secret_env_vars = {
    for k, s in data.google_secret_manager_secret.cloud_run_candidate_portal :
    k => {
      secret  = s.name
      version = "latest"
    }
  }

  # Shared database connection config (used by server and migration job)
  db_connection_uri = "postgres://${var.db_user}:${var.db_password}@${module.database.private_ip_address}:5432/${var.database_name}"
}

# Cloud Run - Server
module "cloud_run_server" {
  source = "./modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  environment           = var.environment
  service_account_email = google_service_account.cloud_run_server.email

  service_name        = "${var.resource_name_prefix}-server"
  image               = "${var.region}-docker.pkg.dev/${var.project_id}/${local.artifact_registry_repository_id}/server:${var.server_image_tag}"
  port                = 4000
  health_check_path   = "/api"
  allow_public_access = true

  vpc_connector_id = module.networking.vpc_connector_id

  env_vars = {
    NODE_ENV    = "production"
    ENVIRONMENT = var.environment
    TZ          = var.timezone

    # Configuration
    ACCESS_TOKEN_LIFETIME = var.access_token_lifetime

    # Infrastructure
    TYPEORM_URI        = local.db_connection_uri
    TYPEORM_SSL        = "false"
    TYPEORM_POOL_SIZE  = tostring(var.db_pool_size)
    PGBOSS_POOL_SIZE   = tostring(var.pgboss_pool_size)
    TYPESENSE_HOST     = module.typesense.internal_ip
    TYPESENSE_PORT     = module.typesense.port
    TYPESENSE_PROTOCOL = "http"
    REDIS_URL          = "redis://${module.redis.host}:${module.redis.port}"

    # URL mapping
    ATS_URL              = "https://${var.domain_ats}"
    CANDIDATE_PORTAL_URL = "https://${var.domain_candidate_portal}"
    EMPLOYER_PORTAL_URL  = "https://${var.domain_employer_portal}"

    # API keys
    SENTRY_DSN = local.cloud_run_server_secret_env_vars["SENTRY_DSN_SERVER"].secret # normal added by secret envs, but we're using an alias here.

  }

  secret_env_vars = {
    for k, v in local.cloud_run_server_secret_env_vars : k => v
  }

  cpu_limit     = "1"
  memory_limit  = "512Mi"
  min_instances = 1
  max_instances = 10

  depends_on = [
    google_artifact_registry_repository.docker_repo,
    google_project_iam_member.cloud_run_artifact_registry,
    google_project_iam_member.cloud_run_cloudsql,
    google_project_iam_member.cloud_run_secretmanager,
    terraform_data.wait_for_cloud_run_iam_propagation,
    module.networking,
    module.database,
    module.redis,
    module.typesense
  ]
}

# Cloud Run Job - Database Migration
# Runs TypeORM migrations from within the VPC (can access private Cloud SQL)
# Triggered via: gcloud run jobs execute <prefix>-database-migration-<environment> (see resource_name_prefix)
resource "google_cloud_run_v2_job" "database_migration" {
  name                = "${var.resource_name_prefix}-database-migration-${var.environment}"
  location            = var.region
  deletion_protection = false

  template {
    template {
      service_account = google_service_account.cloud_run_server.email
      timeout         = "600s" # 10 minutes max

      vpc_access {
        connector = module.networking.vpc_connector_id
        egress    = "ALL_TRAFFIC"
      }

      containers {
        image   = "${var.region}-docker.pkg.dev/${var.project_id}/${local.artifact_registry_repository_id}/server:${var.server_image_tag}"
        command = ["node"]
        args    = ["-r", "dotenv/config", "./node_modules/typeorm/cli", "-d", "./dist/src/config/sql/sources/main.js", "migration:run"]

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }

        env {
          name  = "NODE_ENV"
          value = "production"
        }
        env {
          name  = "TYPEORM_URI"
          value = local.db_connection_uri
        }
        env {
          name  = "TYPEORM_SSL"
          value = "false"
        }
        env {
          name  = "TYPEORM_POOL_SIZE"
          value = "3" # Small pool for migrations (runs once, doesn't need many connections)
        }
      }
    }
  }

  depends_on = [
    google_artifact_registry_repository.docker_repo,
    google_project_iam_member.cloud_run_artifact_registry,
    google_project_iam_member.cloud_run_cloudsql,
    module.database
  ]
}

# Cloud Run Job - Database Seeding
# Seeds the database with initial data (OAuth client, roles, admin user)
# Triggered via: gcloud run jobs execute <prefix>-seed-<environment>
resource "google_cloud_run_v2_job" "seed" {
  name                = "${var.resource_name_prefix}-seed-${var.environment}"
  location            = var.region
  deletion_protection = false

  template {
    template {
      service_account = google_service_account.cloud_run_server.email
      timeout         = "300s" # 5 minutes max

      vpc_access {
        connector = module.networking.vpc_connector_id
        egress    = "ALL_TRAFFIC"
      }

      containers {
        image   = "${var.region}-docker.pkg.dev/${var.project_id}/${local.artifact_registry_repository_id}/server:${var.server_image_tag}"
        command = ["node"]
        args    = ["-r", "dotenv/config", "./dist/src/entrypoints/seed.js"]

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }

        env {
          name  = "NODE_ENV"
          value = "production"
        }
        env {
          name  = "TYPEORM_URI"
          value = local.db_connection_uri
        }
        env {
          name  = "TYPEORM_SSL"
          value = "false"
        }
      }
    }
  }

  depends_on = [
    google_artifact_registry_repository.docker_repo,
    google_project_iam_member.cloud_run_artifact_registry,
    google_project_iam_member.cloud_run_cloudsql,
    module.database
  ]
}

# Cloud Run Job - Typesense Migration
# Creates/updates Typesense collections and imports data from PostgreSQL
# Triggered via: gcloud run jobs execute <prefix>-typesense-migration-<environment>
resource "google_cloud_run_v2_job" "typesense_migration" {
  name                = "${var.resource_name_prefix}-typesense-migration-${var.environment}"
  location            = var.region
  deletion_protection = false

  template {
    template {
      service_account = google_service_account.cloud_run_server.email
      timeout         = "1800s" # 30 minutes max (large datasets may take time)

      vpc_access {
        connector = module.networking.vpc_connector_id
        egress    = "ALL_TRAFFIC"
      }

      containers {
        image   = "${var.region}-docker.pkg.dev/${var.project_id}/${local.artifact_registry_repository_id}/server:${var.server_image_tag}"
        command = ["node"]
        args    = ["-r", "dotenv/config", "./dist/src/entrypoints/typesense-migrate.js"]

        resources {
          limits = {
            cpu    = "2"
            memory = "1Gi"
          }
        }

        env {
          name  = "NODE_ENV"
          value = "production"
        }
        env {
          name  = "TYPEORM_URI"
          value = local.db_connection_uri
        }
        env {
          name  = "TYPEORM_SSL"
          value = "false"
        }
        env {
          name  = "TYPEORM_POOL_SIZE"
          value = "5"
        }
        env {
          name  = "TYPESENSE_HOST"
          value = module.typesense.internal_ip
        }
        env {
          name  = "TYPESENSE_PORT"
          value = module.typesense.port
        }
        env {
          name  = "TYPESENSE_PROTOCOL"
          value = "http"
        }
        env {
          name  = "REDIS_URL"
          value = "redis://${module.redis.host}:${module.redis.port}"
        }

        dynamic "env" {
          for_each = local.cloud_run_server_secret_env_vars
          content {
            name = env.key
            value_source {
              secret_key_ref {
                secret  = env.value.secret
                version = env.value.version
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    google_artifact_registry_repository.docker_repo,
    google_project_iam_member.cloud_run_artifact_registry,
    google_project_iam_member.cloud_run_cloudsql,
    google_project_iam_member.cloud_run_secretmanager,
    terraform_data.wait_for_cloud_run_iam_propagation,
    module.database,
    module.redis,
    module.typesense
  ]
}

# Cloud Run - ATS
module "cloud_run_ats" {
  source = "./modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  environment           = var.environment
  service_account_email = google_service_account.cloud_run_clients.email

  service_name          = "${var.resource_name_prefix}-ats"
  image                 = "${var.region}-docker.pkg.dev/${var.project_id}/${local.artifact_registry_repository_id}/ats:${var.ats_image_tag}"
  port                  = 3000
  enable_liveness_probe = false

  # Note: VITE_* variables are build-time only and must be passed as --build-arg during Docker build.
  # See .github/workflows/release.yml build-ats job.
  env_vars = {
    NODE_ENV    = "production"
    ENVIRONMENT = var.environment
  }

  secret_env_vars = {
    for k, v in local.cloud_run_ats_secret_env_vars : k => v
  }

  cpu_limit     = "1"
  memory_limit  = "512Mi"
  min_instances = var.cloud_run_min_instances
  max_instances = 10

  depends_on = [
    google_artifact_registry_repository.docker_repo,
    google_project_iam_member.cloud_run_artifact_registry,
    google_project_iam_member.cloud_run_secretmanager,
    terraform_data.wait_for_cloud_run_iam_propagation,
    module.cloud_run_server
  ]
}

# Cloud Run - Candidate Portal
module "cloud_run_candidate_portal" {
  source = "./modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  environment           = var.environment
  service_account_email = google_service_account.cloud_run_clients.email

  service_name          = "${var.resource_name_prefix}-candidate-portal"
  image                 = "${var.region}-docker.pkg.dev/${var.project_id}/${local.artifact_registry_repository_id}/candidate-portal:${var.candidate_portal_image_tag}"
  port                  = 3000
  enable_liveness_probe = false

  # Note: NUXT_PUBLIC_* variables are build-time only and must be passed as --build-arg during Docker build.
  # See .github/workflows/release.yml build-candidate-portal job.
  env_vars = {
    NODE_ENV                 = "production"
    ENVIRONMENT              = var.environment
    NUXT_PUBLIC_BACKEND_URL  = "https://${var.domain_server}"
    NUXT_PUBLIC_ATS_BASE_URL = "https://${var.domain_ats}"
    NUXT_PUBLIC_ENVIRONMENT  = var.environment
  }

  secret_env_vars = {
    NUXT_PUBLIC_GOOGLE_API_KEY = local.cloud_run_candidate_portal_secret_env_vars["GOOGLE_API_KEY"]
    NUXT_PUBLIC_SENTRY_DSN     = local.cloud_run_candidate_portal_secret_env_vars["SENTRY_DSN_CANDIDATE_PORTAL"]
  }

  cpu_limit     = "1"
  memory_limit  = "512Mi"
  min_instances = var.cloud_run_min_instances
  max_instances = 10

  depends_on = [
    google_artifact_registry_repository.docker_repo,
    google_project_iam_member.cloud_run_artifact_registry,
    terraform_data.wait_for_cloud_run_iam_propagation,
    module.cloud_run_server
  ]
}

# Cloud Run - Employer Portal
module "cloud_run_employer_portal" {
  source = "./modules/cloud-run"

  project_id            = var.project_id
  region                = var.region
  environment           = var.environment
  service_account_email = google_service_account.cloud_run_clients.email

  service_name          = "${var.resource_name_prefix}-employer-portal"
  image                 = "${var.region}-docker.pkg.dev/${var.project_id}/${local.artifact_registry_repository_id}/employer-portal:${var.employer_portal_image_tag}"
  port                  = 3000
  enable_liveness_probe = false

  # Note: VITE_* variables are build-time only and must be passed as --build-arg during Docker build.
  # See .github/workflows/release.yml build-employer-portal job.
  env_vars = {
    NODE_ENV    = "production"
    ENVIRONMENT = var.environment
  }

  cpu_limit     = "1"
  memory_limit  = "512Mi"
  min_instances = var.cloud_run_min_instances
  max_instances = 10

  depends_on = [
    google_artifact_registry_repository.docker_repo,
    google_project_iam_member.cloud_run_artifact_registry,
    terraform_data.wait_for_cloud_run_iam_propagation,
    module.cloud_run_server
  ]
}

# =============================================================================
# Global HTTP(S) Load Balancer with Managed SSL Certificates
# =============================================================================
# This section creates a Global Load Balancer for custom domain support.
# After applying, point your DNS A records to the load_balancer_ip output.

locals {
  # Build a map of services that have custom domains configured
  lb_services = var.enable_load_balancer ? {
    for k, v in {
      server             = { domain = var.domain_server, service = module.cloud_run_server }
      ats                = { domain = var.domain_ats, service = module.cloud_run_ats }
      "candidate-portal" = { domain = var.domain_candidate_portal, service = module.cloud_run_candidate_portal }
      "employer-portal"  = { domain = var.domain_employer_portal, service = module.cloud_run_employer_portal }
    } : k => v if v.domain != ""
  } : {}

  # List of all domains for SSL certificate
  # Flatten the domains list, injecting the "prod." variant only for the server in production
  lb_domains = flatten([
    for k, v in local.lb_services : [
      v.domain,
      (k == "server" && var.environment == "production") ? ["prod.${v.domain}"] : []
    ]
    if contains(keys(local.lb_services), k)
  ])
}

# Reserve a global static IP address for the load balancer
resource "google_compute_global_address" "lb_ip" {
  count = var.enable_load_balancer && length(local.lb_services) > 0 ? 1 : 0

  name        = "${var.resource_name_prefix}-lb-ip-${var.environment}"
  description = "Static IP for global load balancer (${var.environment})"

  depends_on = [google_project_service.services]
}

# Managed SSL certificate (Google-managed, auto-renews)
resource "google_compute_managed_ssl_certificate" "lb_cert" {
  count = var.enable_load_balancer && length(local.lb_services) > 0 ? 1 : 0

  name = "${var.resource_name_prefix}-ssl-cert-${var.environment}"

  # Updating certificate domains will cause the certificate to be recreated -> downtime
  # Necessady because SSL certificates were created in Google Cloud Console
  managed {
    domains = local.lb_domains
  }

  lifecycle {
    ignore_changes = [managed]
  }

  depends_on = [google_project_service.services]
}

# Serverless NEG for each Cloud Run service
resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  for_each = local.lb_services

  name                  = "${var.resource_name_prefix}-neg-${each.key}-${var.environment}"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = each.value.service.service_name
  }

  depends_on = [google_project_service.services]
}

# Backend service for each Cloud Run service
resource "google_compute_backend_service" "cloud_run_backend" {
  for_each = local.lb_services

  name        = "${var.resource_name_prefix}-backend-${each.key}-${var.environment}"
  description = "Backend service for ${each.key} (${var.environment})"

  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  # Enable Cloud CDN for frontend services (optional, good for static assets)
  enable_cdn = contains(["ats", "candidate-portal", "employer-portal"], each.key)

  dynamic "cdn_policy" {
    for_each = contains(["ats", "candidate-portal", "employer-portal"], each.key) ? [1] : []
    content {
      cache_mode                   = "CACHE_ALL_STATIC"
      default_ttl                  = 3600
      max_ttl                      = 86400
      client_ttl                   = 3600
      negative_caching             = true
      signed_url_cache_max_age_sec = 0

      cache_key_policy {
        include_host         = true
        include_protocol     = true
        include_query_string = true
      }
    }
  }

  backend {
    group = google_compute_region_network_endpoint_group.cloud_run_neg[each.key].id
  }

  # IAP disabled - public access
  iap {
    enabled = false
  }

  depends_on = [google_project_service.services]
}

# URL Map - Routes traffic based on hostname
resource "google_compute_url_map" "lb_url_map" {
  count = var.enable_load_balancer && length(local.lb_services) > 0 ? 1 : 0

  name            = "${var.resource_name_prefix}-lb-url-map-${var.environment}"
  description     = "URL map for HTTPS load balancer (${var.environment})"
  default_service = google_compute_backend_service.cloud_run_backend[keys(local.lb_services)[0]].id

  # Host rules - route based on domain
  dynamic "host_rule" {
    for_each = local.lb_services
    content {
      hosts = flatten([
        host_rule.value.domain,
        (host_rule.key == "server" && var.environment == "production") ? ["prod.${host_rule.value.domain}"] : []
      ])
      path_matcher = host_rule.key
    }
  }

  # Path matchers - one per service (all paths go to the same backend)
  dynamic "path_matcher" {
    for_each = local.lb_services
    content {
      name            = path_matcher.key
      default_service = google_compute_backend_service.cloud_run_backend[path_matcher.key].id
    }
  }
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "lb_https_proxy" {
  count = var.enable_load_balancer && length(local.lb_services) > 0 ? 1 : 0

  name             = "${var.resource_name_prefix}-lb-https-proxy-${var.environment}"
  url_map          = google_compute_url_map.lb_url_map[0].id
  ssl_certificates = [google_compute_managed_ssl_certificate.lb_cert[0].id]
}

# Global Forwarding Rule (HTTPS)
resource "google_compute_global_forwarding_rule" "lb_https" {
  count = var.enable_load_balancer && length(local.lb_services) > 0 ? 1 : 0

  name                  = "${var.resource_name_prefix}-lb-https-${var.environment}"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.lb_https_proxy[0].id
  ip_address            = google_compute_global_address.lb_ip[0].id
}

# HTTP to HTTPS redirect
resource "google_compute_url_map" "http_redirect" {
  count = var.enable_load_balancer && length(local.lb_services) > 0 ? 1 : 0

  name = "${var.resource_name_prefix}-http-redirect-${var.environment}"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "http_redirect" {
  count = var.enable_load_balancer && length(local.lb_services) > 0 ? 1 : 0

  name    = "${var.resource_name_prefix}-http-redirect-proxy-${var.environment}"
  url_map = google_compute_url_map.http_redirect[0].id
}

resource "google_compute_global_forwarding_rule" "lb_http" {
  count = var.enable_load_balancer && length(local.lb_services) > 0 ? 1 : 0

  name                  = "${var.resource_name_prefix}-lb-http-${var.environment}"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_redirect[0].id
  ip_address            = google_compute_global_address.lb_ip[0].id
}
