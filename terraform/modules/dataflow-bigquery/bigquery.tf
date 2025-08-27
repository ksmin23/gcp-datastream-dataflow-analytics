# Create the BigQuery datasets for final and staging data
resource "google_bigquery_dataset" "analytics_dataset" {
  project                    = var.project_id
  dataset_id                 = var.bigquery_dataset_name
  location                   = var.bigquery_dataset_location
  delete_contents_on_destroy = true
  depends_on                 = [google_project_service.apis]
}

resource "google_bigquery_dataset" "staging_dataset" {
  project                    = var.project_id
  dataset_id                 = var.bigquery_staging_dataset_name
  location                   = var.bigquery_dataset_location
  delete_contents_on_destroy = true
  depends_on                 = [google_project_service.apis]
}
