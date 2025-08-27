variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be created."
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC network."
  type        = string
  default     = "gcp-ds-cdc-vpc"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet."
  type        = string
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet."
  type        = string
}

variable "psc_subnet_cidr_range" {
  description = "The CIDR block for the Datastream PSC subnet. This will be passed to the 'psc_subnet_cidr_range' variable in the network module."
  type        = string
}

variable "existing_peering_ranges" {
  description = "The CIDR for the Datastream private connection peering. This will be passed to the 'existing_peering_ranges' variable in the network module."
  type        = list(string)
  default     = []
}

variable "allowed_psc_projects" {
  description = "A list of consumer projects allowed to connect via PSC. Must include your project ID."
  type        = list(string)
}

variable "staging_bucket_name" {
  description = "The name of the GCS bucket for Datastream staging."
  type        = string
}

variable "db_instance_name" {
  description = "The name of the Cloud SQL database instance."
  type        = string
  default     = "mysql-src-ds"
}

variable "db_version" {
  description = "The version for the Cloud SQL for MySQL instance."
  type        = string
  default     = "MYSQL_8_0"
}

variable "db_tier" {
  description = "The machine type for the Cloud SQL instance."
  type        = string
  default     = "db-n1-standard-2"
}

variable "datastream_psc_name" {
  description = "The name for the Datastream private connection."
  type        = string
  default     = "mysql-private-connection-psc"
}

variable "datastream_src_conn_profile_name" {
  description = "The name of the connection profile."
  type        = string
  default     = "mysql-source-conn-profile"
}

variable "datastream_dest_conn_profile_name" {
  description = "The name of the GCS destination connection profile."
  type        = string
  default     = "gcs-dest-conn-profile"
}

variable "datastream_name" {
  description = "The name for the Datastream stream."
  type        = string
  default     = "mysql-cdc-stream"
}

variable "dataflow_job_name" {
  description = "The name for the Dataflow job."
  type        = string
}

variable "dataflow_template_version" {
  description = "The version of the Dataflow template to use."
  type        = string
  default     = "2025-08-19-00_RC00"
}

variable "dataflow_input_file_format" {
  description = "The format of the Datastream output files (e.g., 'avro')."
  type        = string
  default     = "avro"
}

variable "dataflow_merge_frequency_minutes" {
  description = "The frequency (in minutes) for the Dataflow merge operation."
  type        = number
}

variable "dataflow_dead_letter_gcs_path" {
  description = "The GCS path for the Dataflow dead-letter queue."
  type        = string
}

variable "bigquery_dataset_name" {
  description = "The name of the BigQuery dataset for the final data."
  type        = string
}

variable "bigquery_staging_dataset_name" {
  description = "The name of the BigQuery dataset for staging data."
  type        = string
}

variable "bigquery_dataset_location" {
  description = "The location for the BigQuery dataset."
  type        = string
  default     = "US"
}