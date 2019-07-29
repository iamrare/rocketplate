variable "ALERTS_SLACK_WEBHOOK_URL" { type = "string" }

data "archive_file" "archive_file" {
  type = "zip"
  source_dir  = "${path.root}/cloud-build-alert/"
  output_path = "${path.root}/cloud-build-alert/build.zip"
}

resource "google_storage_bucket" "bucket" {
  name = "acelerate-cloud-functions"
}

resource "google_storage_bucket_object" "archive" {
  name = "cloud-build-alert.zip"
  bucket = "${google_storage_bucket.bucket.name}"
  source = "${path.root}/cloud-build-alert/build.zip"
}

resource "google_cloudfunctions_function" "function" {
  name = "cloudBuildAlert"
  description = "Alerts slack channel with Google Cloud Builds"
  runtime = "nodejs10"

  available_memory_mb = 256
  source_archive_bucket = "${google_storage_bucket.bucket.name}"
  source_archive_object = "${google_storage_bucket_object.archive.name}"
  entry_point = "cloudBuildAlert"

  environment_variables = {
    ALERTS_SLACK_WEBHOOK_URL = var.ALERTS_SLACK_WEBHOOK_URL
  }

  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource = "cloud-builds"
    failure_policy {
      retry = false
    }
  }
}
