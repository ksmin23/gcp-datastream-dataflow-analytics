# Enable necessary Google Cloud APIs
resource "google_project_service" "apis" {
  project = var.project_id
  for_each = toset([
    "serviceusage.googleapis.com",
    "dataflow.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "pubsub.googleapis.com"
  ])
  service                    = each.key
  disable_dependent_services = true
  disable_on_destroy         = false
}
