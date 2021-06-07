resource "google_cloud_run_service" "main" {
  autogenerate_revision_name = false
  name                       = var.name
  location                   = var.region

  metadata {
    annotations = {
      "run.googleapis.com/ingress"        = "internal-and-cloud-load-balancing"
      "run.googleapis.com/ingress-status" = "internal-and-cloud-load-balancing"
    }
  }

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10"
      }
    }

    spec {
      container_concurrency = 1
      timeout_seconds       = 3600

      containers {
        args    = []
        command = []
        image   = "us-docker.pkg.dev/cloudrun/container/hello"

        ports {
          container_port = 8080
        }

        resources {
          limits = {
            "cpu"    = "1000m"
            "memory" = "512Mi"
          }
          requests = {}
        }
      }
    }
  }

  timeouts {}

  traffic {
    latest_revision = true
    percent         = 100
  }

  lifecycle {
    ignore_changes = [
      template[0].spec[0].containers[0].image,
      template[0].spec[0].service_account_name,
      template[0].metadata[0].annotations,
      metadata[0].annotations,
    ]
  }
}
