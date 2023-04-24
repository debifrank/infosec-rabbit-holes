terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

data "google_project" "project" {
  project_id = var.project_id
}

data "google_cloud_run_service" "run-service" {
  name     = var.project_id
  project  = var.project_id
  location = google_cloudfunctions2_function.function.location
  depends_on = [
    google_cloudfunctions2_function.function
  ]
}

resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket_iam_binding" "binding" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  ]
}

resource "google_storage_bucket" "bucket" {
  name                        = "${random_id.bucket_prefix.hex}-vulnapp2-source"
  location                    = "US"
  uniform_bucket_level_access = true
  project                     = var.project_id
}

resource "google_storage_bucket_object" "object" {
  name   = "vulnapp2.zip"
  bucket = google_storage_bucket.bucket.name
  source = "vulnapp2.zip"
}

resource "google_cloud_run_service_iam_binding" "binding" {
  project  = data.google_cloud_run_service.run-service.project
  location = data.google_cloud_run_service.run-service.location
  service  = data.google_cloud_run_service.run-service.name
  role     = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}

resource "google_cloudfunctions2_function" "function" {
  name        = "vulnapp2"
  location    = "us-central1"
  description = "A vulnerable google cloud function for learning methods of abuse."
  project     = var.project_id
  build_config {
    runtime     = "python39"
    entry_point = "vulnapp2"
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60

    secret_volumes {
      mount_path = "/secrets"
      project_id = var.project_id
      secret     = google_secret_manager_secret.secret.secret_id
    }

    secret_environment_variables {
      key        = "VULNAPP2-SECRET"
      project_id = var.project_id
      secret     = google_secret_manager_secret.secret.secret_id
      version    = "latest"
    }
  }
  depends_on = [
    google_secret_manager_secret_version.secret
  ]
}

resource "google_secret_manager_secret_iam_binding" "binding" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  members = [
    "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  ]
}

resource "google_secret_manager_secret" "secret" {
  secret_id = "vulnapp2-secret"
  project   = var.project_id
  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
    }
  }
}

resource "google_secret_manager_secret_version" "secret" {
  secret = google_secret_manager_secret.secret.name

  secret_data = "SuperSecret123"
  enabled     = true
}

output "function_uri" {
  value = google_cloudfunctions2_function.function.service_config[0].uri
}