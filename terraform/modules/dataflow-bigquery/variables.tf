# GCP Project Details
variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The primary GCP region for all resources."
  type        = string
}

# Input from Network Module
variable "vpc_name" {
  description = "The name of the VPC network to deploy resources into."
  type        = string
}

variable "subnet_self_link" {
  description = "The self-link of the subnet for application infrastructure."
  type        = string
}

# Input from datastream-gcs Module
variable "datastream_gcs_path" {
  description = "The GCS path where Datastream writes CDC data."
  type        = string
}

variable "pubsub_topic_id" {
  description = "The ID of the Pub/Sub topic for GCS notifications."
  type        = string
}

# Dataflow Configuration
variable "dataflow_job_name" {
  description = "A unique name for the Dataflow job."
  type        = string
}

variable "dataflow_input_file_format" {
  description = "The format of the Datastream output files (e.g., 'avro')."
  type        = string
  default     = "avro"
}

variable "dataflow_template_version" {
  description = "The version of the Dataflow template to use (e.g., 'latest')."
  type        = string
  default     = "2025-08-19-00_RC00"
}

variable "dataflow_merge_frequency_minutes" {
  description = "The frequency (in minutes) for the Dataflow job to merge data into BigQuery."
  type        = string
}

variable "dataflow_dead_letter_gcs_path" {
  description = "The GCS path to write failed Dataflow messages to."
  type        = string
}

# BigQuery Configuration
variable "bigquery_dataset_name" {
  description = "The name of the BigQuery dataset to create for replica tables."
  type        = string
}

variable "bigquery_staging_dataset_name" {
  description = "The name of the BigQuery dataset to create for staging tables."
  type        = string
}

variable "bigquery_dataset_location" {
  description = "The location for the BigQuery dataset."
  type        = string
  default     = "US"
}
