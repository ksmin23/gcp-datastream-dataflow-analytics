# Create Service Account and Permissions for Dataflow
resource "google_service_account" "dataflow_sa" {
  project      = var.project_id
  account_id   = "dataflow-job-sa-${random_id.id.hex}"
  display_name = "Dataflow Job Service Account"
}

resource "google_project_iam_member" "dataflow_sa_permissions" {
  project = var.project_id
  for_each = toset([
    "roles/dataflow.worker",
    "roles/datastream.viewer",
    "roles/storage.objectAdmin",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/pubsub.viewer"
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

# Create Pub/Sub Subscription for Dataflow
resource "google_pubsub_subscription" "dataflow_subscription" {
  project              = var.project_id
  name                 = "dataflow-gcs-subscription-${random_id.id.hex}"
  topic                = var.pubsub_topic_id
  ack_deadline_seconds = 120

  # Grant the Dataflow service account permission to consume messages
  # This is often necessary for the Dataflow job to pull from the subscription.
  depends_on = [google_project_service.apis]
}

resource "google_pubsub_subscription_iam_member" "dataflow_subscriber_permissions" {
  project      = var.project_id
  subscription = google_pubsub_subscription.dataflow_subscription.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_sa.email}"
}

# Create the Dataflow job to process data from GCS to BigQuery
resource "google_dataflow_flex_template_job" "datastream_to_bigquery" {
  provider                     = google-beta
  project                      = var.project_id
  region                       = var.region
  name                         = var.dataflow_job_name
  container_spec_gcs_path      = format("gs://dataflow-templates-%s/%s/flex/Cloud_Datastream_to_BigQuery", var.region, var.dataflow_template_version)
  service_account_email        = google_service_account.dataflow_sa.email
  network                      = var.vpc_name
  subnetwork                   = var.subnet_self_link
  ip_configuration             = "WORKER_IP_PRIVATE"
  skip_wait_on_job_termination = true
  parameters = {
    inputFilePattern             = "${var.datastream_gcs_path}/"
    inputFileFormat              = var.dataflow_input_file_format
    gcsPubSubSubscription        = google_pubsub_subscription.dataflow_subscription.id
    outputStagingDatasetTemplate = google_bigquery_dataset.staging_dataset.dataset_id
    outputDatasetTemplate        = google_bigquery_dataset.analytics_dataset.dataset_id
    deadLetterQueueDirectory     = var.dataflow_dead_letter_gcs_path
    mergeFrequencyMinutes        = var.dataflow_merge_frequency_minutes
  }
  depends_on = [
    google_project_iam_member.dataflow_sa_permissions,
    google_pubsub_subscription_iam_member.dataflow_subscriber_permissions
  ]
}
