resource "google_service_account" "pubsub_social_dashboard" {
  account_id   = "pubsub-social-dashboard"
  display_name = "pubsub-social-dashboard"
}

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
      service_account_email = google_service_account.pubsub_social_dashboard.email
    }
  }

  dead_letter_policy {
    max_delivery_attempts = 5
    dead_letter_topic     = google_pubsub_topic.jasso_gakuseiseikatsu_stats_importer_dl.id
  }

  retry_policy {
    maximum_backoff = "600s"
    minimum_backoff = "10s"
  }

  timeouts {}
}

resource "google_pubsub_subscription" "jasso_gakuseiseikatsu_stats_importer_dl" {
  ack_deadline_seconds       = 10
  enable_message_ordering    = false
  labels                     = {}
  message_retention_duration = "604800s"
  name                       = "jasso-gakuseiseikatsu-stats-importer-dl"
  retain_acked_messages      = false
  topic                      = google_pubsub_topic.jasso_gakuseiseikatsu_stats_importer_dl.id

  expiration_policy {
    ttl = "2678400s"
  }

  timeouts {}
}

resource "google_pubsub_topic" "e_stat_kakei_chousa_importer" {
  name = "e-stat-kakei-chousa-importer"
}

resource "google_pubsub_topic" "e_stat_importer_dl" {
  name = "e-stat-kakei-chousa-importer-dl"
}

resource "google_pubsub_subscription" "e_stat_kakei_chousa_importer" {
  ack_deadline_seconds       = 10
  enable_message_ordering    = false
  labels                     = {}
  message_retention_duration = "604800s"
  name                       = "e-stat-kakei-chousa-importer"
  retain_acked_messages      = false
  topic                      = google_pubsub_topic.e_stat_kakei_chousa_importer.id

  expiration_policy {
    ttl = "2678400s"
  }

  push_config {
    attributes    = {}
    push_endpoint = module.runner["e-stat-kakei-chousa-importer"].url

    oidc_token {
      service_account_email = google_service_account.pubsub_social_dashboard.email
    }
  }

  dead_letter_policy {
    max_delivery_attempts = 5
    dead_letter_topic     = google_pubsub_topic.e_stat_importer_dl.id
  }

  retry_policy {
    maximum_backoff = "600s"
    minimum_backoff = "10s"
  }

  timeouts {}
}

resource "google_pubsub_subscription" "e_stat_importer_dl" {
  ack_deadline_seconds       = 10
  enable_message_ordering    = false
  labels                     = {}
  message_retention_duration = "604800s"
  name                       = "e-stat-kakei-chousa-importer-dl"
  retain_acked_messages      = false
  topic                      = google_pubsub_topic.e_stat_importer_dl.id

  expiration_policy {
    ttl = "2678400s"
  }

  timeouts {}
}
