resource "google_data_catalog_tag_template" "data_ingestion" {
  tag_template_id = "data_ingestion"
  display_name    = "Data Ingestion"

  fields {
    display_name = "License"
    description  = "Data License"
    field_id     = "license"
    is_required  = true
    order        = 0

    type {
      primitive_type = "STRING"
    }
  }
  fields {
    display_name = "Last ETL Job End"
    description  = "End-time of most recent ingestion job"
    field_id     = "latest_job_end_datetime"
    is_required  = false
    order        = 10

    type {
      primitive_type = "TIMESTAMP"
    }
  }
  fields {
    display_name = "Last ETL Job Runtime"
    description  = "How long the most recent ETL job was running"
    field_id     = "latest_job_run_time"
    is_required  = false
    order        = 9

    type {
      primitive_type = "STRING"
    }
  }
  fields {
    display_name = "Data Ingestion Owner"
    description  = "Name of the user to contact regarding ingestion issues and questions"
    field_id     = "data_ingestion_owner"
    is_required  = false
    order        = 13

    type {
      primitive_type = "STRING"
    }
  }
  fields {
    display_name = "Number of Errors"
    description  = "Specifies how many errors have occurred during most recent ETL job"
    field_id     = "errors"
    is_required  = false
    order        = 1

    type {
      primitive_type = "DOUBLE"
    }
  }
  fields {
    display_name = "Number of Warnings"
    description  = "Specifies how many warnings have occurred during most recent ETL job"
    field_id     = "warnings"
    is_required  = false
    order        = 2

    type {
      primitive_type = "DOUBLE"
    }
  }
  fields {
    display_name = "Data Sources of ETL Job"
    description  = "Specifies the source of the data asset"
    field_id     = "data_sources"
    is_required  = false
    order        = 8

    type {
      primitive_type = "STRING"
    }
  }
  fields {
    display_name = "PII Data Sources"
    description  = "Specifies whether all source data contains PII"
    field_id     = "data_sources_have_pii"
    is_required  = false
    order        = 6

    type {
      primitive_type = "BOOL"
    }
  }
  fields {
    display_name = "Data Sources Approved"
    description  = "Specifies whether all source data was approved"
    field_id     = "data_sources_approved_all"
    is_required  = false
    order        = 7

    type {
      primitive_type = "BOOL"
    }
  }
  fields {
    display_name = "Rows to Reprocess"
    description  = "The number of rows that need reprocessing"
    field_id     = "rows_for_reprocessing"
    is_required  = false
    order        = 3

    type {
      primitive_type = "DOUBLE"
    }
  }
  fields {

    display_name = "Rows Added"
    description  = "The number of rows/records added during the most recent ETL job run"
    field_id     = "rows_added"
    is_required  = false
    order        = 4

    type {
      primitive_type = "DOUBLE"
    }
  }
  fields {
    display_name = "Rows Processed"
    description  = "The number of rows/records ingested/processed during the most recent ETL job run"
    field_id     = "rows_processed"
    is_required  = false
    order        = 5

    type {
      primitive_type = "DOUBLE"
    }
  }
  fields {
    display_name = "Last ETL Job Start"
    description  = "The start-time of most recent ETL job"
    field_id     = "latest_job_start_datetime"
    is_required  = false
    order        = 11

    type {
      primitive_type = "TIMESTAMP"
    }
  }
  fields {
    description  = "The status of the last ingestion job"
    display_name = "Last ETL Job Status"
    field_id     = "latest_job_status"
    is_required  = false
    order        = 12

    type {
      enum_type {
        allowed_values {
          display_name = "running"
        }
        allowed_values {
          display_name = "failed"
        }
        allowed_values {
          display_name = "interrupted"
        }
        allowed_values {
          display_name = "partial"
        }
        allowed_values {
          display_name = "queued"
        }
        allowed_values {
          display_name = "retrying"
        }
        allowed_values {
          display_name = "completed"
        }
        allowed_values {
          display_name = "skipped"
        }
      }
    }
  }
  timeouts {}
}

resource "google_data_catalog_entry_group" "social_data" {
  description    = "Social Data Entries"
  display_name   = "social-data"
  entry_group_id = "social_data"
}
