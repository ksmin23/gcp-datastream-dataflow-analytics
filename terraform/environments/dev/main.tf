terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.49.1"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.49.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "gcs" {
    bucket = "tfstate-<YOUR_GCP_PROJECT_ID>" # <-- UPDATE THIS
    prefix = "gcp-datastream-dataflow-analytics/terraform"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Instantiate the Network Module
module "network" {
  source                  = "../../modules/network"
  project_id              = var.project_id
  region                  = var.region
  vpc_name                = var.vpc_name
  public_subnet_cidr      = var.public_subnet_cidr
  private_subnet_cidr     = var.private_subnet_cidr
  psc_subnet_cidr_range   = var.psc_subnet_cidr_range
  existing_peering_ranges = var.existing_peering_ranges
}

# Instantiate the Datastream to GCS Module
module "datastream-gcs" {
  source = "../../modules/datastream-gcs"

  # GCP Project Details
  project_id = var.project_id
  region     = var.region

  # Input from Network Module
  vpc_id                             = module.network.vpc_id
  vpc_self_link                      = module.network.vpc_self_link
  private_subnet_ids                 = module.network.private_subnet_ids
  datastream_psc_subnet_self_link    = module.network.datastream_psc_subnet_self_link
  datastream_psc_subnet_cidr         = module.network.datastream_psc_subnet_cidr
  private_service_connection_network = module.network.private_service_connection_network

  # Cloud SQL (MySQL) Configuration
  allowed_psc_projects             = var.allowed_psc_projects
  db_instance_name                 = var.db_instance_name
  db_version                       = var.db_version
  db_tier                          = var.db_tier
  datastream_psc_name              = var.datastream_psc_name
  datastream_src_conn_profile_name = var.datastream_src_conn_profile_name
  datastream_name                  = var.datastream_name

  # GCS Staging Bucket
  staging_bucket_name               = var.staging_bucket_name
  datastream_dest_conn_profile_name = var.datastream_dest_conn_profile_name
}

# Instantiate the Dataflow to BigQuery Module
module "dataflow-bigquery" {
  source = "../../modules/dataflow-bigquery"

  # GCP Project Details
  project_id = var.project_id
  region     = var.region

  # Input from Network Module
  vpc_name         = module.network.network_name
  subnet_self_link = module.network.private_subnet_self_links[0]

  # Input from datastream-gcs Module
  datastream_gcs_path = module.datastream-gcs.datastream_gcs_path
  pubsub_topic_id     = module.datastream-gcs.pubsub_topic_id

  # Dataflow Configuration
  dataflow_job_name                = var.dataflow_job_name
  dataflow_template_version        = var.dataflow_template_version
  dataflow_input_file_format       = var.dataflow_input_file_format
  dataflow_merge_frequency_minutes = var.dataflow_merge_frequency_minutes
  dataflow_dead_letter_gcs_path    = var.dataflow_dead_letter_gcs_path

  # BigQuery Configuration
  bigquery_dataset_name         = var.bigquery_dataset_name
  bigquery_staging_dataset_name = var.bigquery_staging_dataset_name
  bigquery_dataset_location     = var.bigquery_dataset_location
}

output "cloud_sql_instance_name" {
  description = "The name of the Cloud SQL for MySQL instance."
  value       = module.datastream-gcs.cloud_sql_instance_name
}

output "cloud_sql_instance_private_ip" {
  description = "The private IP address of the Cloud SQL instance."
  value       = module.datastream-gcs.cloud_sql_instance_private_ip
  sensitive   = true
}

output "admin_user_name" {
  description = "The username for the database admin."
  value       = module.datastream-gcs.admin_user_name
}

output "admin_user_password" {
  description = "The password for the database admin user."
  value       = module.datastream-gcs.admin_user_password
  sensitive   = true
}

output "datastream_user_name" {
  description = "The username for the Cloud SQL user for Datastream."
  value       = module.datastream-gcs.datastream_user_name
}

output "datastream_user_password" {
  description = "The password for the Cloud SQL user for Datastream. This is a sensitive value."
  value       = module.datastream-gcs.datastream_user_password
  sensitive   = true
}

output "gcs_staging_bucket_name" {
  description = "The name of the GCS bucket used for Datastream staging."
  value       = module.datastream-gcs.gcs_staging_bucket_name
}

output "datastream_stream_name" {
  description = "The name of the Datastream stream."
  value       = module.datastream-gcs.datastream_stream_name
}
