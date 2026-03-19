# Cloud Run Service
resource "google_cloud_run_v2_service" "service" {
  name                = "${var.service_name}-${var.environment}"
  location            = var.region
  deletion_protection = var.deletion_protection

  template {
    service_account = var.service_account_email

    containers {
      image = var.image

      ports {
        container_port = var.port
      }

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_env_vars
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

      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }

        cpu_idle = true
      }

      startup_probe {
        initial_delay_seconds = 30
        timeout_seconds       = 10
        period_seconds        = 5
        failure_threshold     = 20

        tcp_socket {
          port = var.port
        }
      }

      dynamic "liveness_probe" {
        for_each = var.enable_liveness_probe ? [1] : []
        content {
          initial_delay_seconds = 10
          timeout_seconds       = 1
          period_seconds        = 10
          failure_threshold     = 3

          http_get {
            path = var.health_check_path
            port = var.port
          }
        }
      }
    }

    # VPC connector for services that need private network access
    dynamic "vpc_access" {
      for_each = var.vpc_connector_id != null ? [1] : []
      content {
        connector = var.vpc_connector_id
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    timeout = "300s"
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# IAM - Allow public access (adjust as needed)
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  count = var.allow_public_access ? 1 : 0

  name     = google_cloud_run_v2_service.service.name
  location = google_cloud_run_v2_service.service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
