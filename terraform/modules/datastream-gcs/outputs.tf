output "cloud_sql_instance_name" {
  description = "The name of the Cloud SQL for MySQL instance."
  value       = google_sql_database_instance.mysql_instance.name
}

output "cloud_sql_instance_private_ip" {
  description = "The private IP address of the Cloud SQL instance."
  value       = google_sql_database_instance.mysql_instance.private_ip_address
  sensitive   = true
}

output "datastream_stream_name" {
  description = "The name of the Datastream stream."
  value       = google_datastream_stream.default.stream_id
}

output "datastream_user_name" {
  description = "The username for the 'datastream' SQL user."
  value       = google_sql_user.datastream_user.name
}

output "datastream_user_password" {
  description = "The password for the 'datastream' SQL user."
  value       = random_password.ds_password.result
  sensitive   = true
}

output "admin_user_name" {
  description = "The username for the database admin."
  value       = google_sql_user.admin_user.name
}

output "admin_user_password" {
  description = "The password for the database admin user."
  value       = random_password.admin_password.result
  sensitive   = true
}

output "cloud_sql_psc_endpoint_ip" {
  description = "The internal IP address of the PSC Endpoint for Cloud SQL. Use this IP for all in-VPC connections."
  value       = google_compute_forwarding_rule.sql_psc_endpoint.ip_address
}

output "gcs_staging_bucket_name" {
  description = "The name of the GCS bucket used for Datastream staging."
  value       = google_storage_bucket.staging_bucket.name
}

output "datastream_gcs_path" {
  description = "The GCS path where Datastream writes CDC data."
  value       = "gs://${google_storage_bucket.staging_bucket.name}${google_datastream_stream.default.destination_config[0].gcs_destination_config[0].path}"
}

output "pubsub_topic_id" {
  description = "The ID of the Pub/Sub topic for GCS notifications."
  value       = google_pubsub_topic.gcs_notifications.id
}