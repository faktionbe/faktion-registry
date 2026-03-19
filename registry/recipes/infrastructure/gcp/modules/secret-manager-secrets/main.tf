resource "google_secret_manager_secret" "secrets" {
  for_each = var.secrets

  secret_id = each.key

  replication {
    user_managed {
      replicas {
        location = "europe-west1"
      }
    }
  }
}

resource "google_secret_manager_secret_version" "secrets" {
  for_each = var.secrets

  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value
}


