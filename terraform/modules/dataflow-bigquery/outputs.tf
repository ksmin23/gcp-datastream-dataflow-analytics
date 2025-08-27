output "bigquery_dataset_id" {
  description = "The ID of the BigQuery dataset."
  value       = google_bigquery_dataset.analytics_dataset.dataset_id
}

output "dataflow_job_name" {
  description = "The name of the Dataflow streaming job."
  value       = google_dataflow_flex_template_job.datastream_to_bigquery.name
}
