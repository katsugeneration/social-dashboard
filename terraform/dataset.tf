resource "google_bigquery_dataset" "social_dataset" {
  dataset_id                 = "social_dataset"
  delete_contents_on_destroy = false
  labels                     = {}
  location                   = "asia-northeast1"

  access {
    role          = "OWNER"
    user_by_email = "katsu.generation.888@gmail.com"
  }
  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }
  access {
    role          = "READER"
    special_group = "projectReaders"
  }
  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }

  timeouts {}
}
