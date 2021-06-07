resource "google_pubsub_topic" "jasso_gakuseiseikatsu_stats_importer" {
  name = "jasso-gakuseiseikatsu-stats-importer"
}

resource "google_pubsub_topic" "jasso_gakuseiseikatsu_stats_importer_dl" {
  name = "jasso-gakuseiseikatsu-stats-importer-dl"
}

resource "google_pubsub_subscription" "jasso_gakuseiseikatsu_stats_importer" {
  ack_deadline_seconds       = 10
  enable_message_ordering    = false
  labels                     = {}
  message_retention_duration = "604800s"
  name                       = "jasso-gakuseiseikatsu-stats-importer"
  retain_acked_messages      = false
  topic                      = google_pubsub_topic.jasso_gakuseiseikatsu_stats_importer.id

  expiration_policy {
    ttl = "2678400s"
  }

  push_config {
    attributes    = {}
    push_endpoint = module.runner["jasso-gakuseiseikatsu-stats-importer"].url

    oidc_token {
      service_account_email = "pubsub-social-dashboard@ml-project-210100.iam.gserviceaccount.com"
    }
  }

  dead_letter_policy {
    dead_letter_topic = google_pubsub_topic.jasso_gakuseiseikatsu_stats_importer_dl.id
  }

  timeouts {}
}
