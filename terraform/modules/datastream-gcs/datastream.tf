resource "random_id" "suffix" {
  byte_length = 4
  keepers = {
    project_id = var.project_id
    region     = var.region
  }
}

# Create GCS bucket for Datastream staging
resource "google_storage_bucket" "staging_bucket" {
  project                     = var.project_id
  name                        = var.staging_bucket_name
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.project_services["storage.googleapis.com"]]
}

# Create Pub/Sub Topic and Notification for GCS
resource "google_pubsub_topic" "gcs_notifications" {
  project    = var.project_id
  name       = "${var.staging_bucket_name}-notifications"
  depends_on = [google_project_service.project_services["pubsub.googleapis.com"]]
}

data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}

resource "google_pubsub_topic_iam_member" "gcs_publish_permissions" {
  project = var.project_id
  topic   = google_pubsub_topic.gcs_notifications.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

resource "google_storage_notification" "bucket_notification" {
  bucket         = google_storage_bucket.staging_bucket.name
  topic          = google_pubsub_topic.gcs_notifications.id
  payload_format = "JSON_API_V1"
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_member.gcs_publish_permissions]
}

# Network Attachment for PSC
resource "google_compute_network_attachment" "ds_to_sql_attachment" {
  name                  = "na-ds-to-sql"
  region                = var.region
  connection_preference = "ACCEPT_AUTOMATIC"
  subnetworks           = [var.datastream_psc_subnet_self_link]
}

# Firewall rule to allow egress from PSC subnet to Cloud SQL
resource "google_compute_firewall" "allow_datastream_psc_to_sql" {
  name      = "fw-allow-ds-psc-to-sql-egress"
  network   = var.vpc_self_link
  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges      = [var.datastream_psc_subnet_cidr]
  destination_ranges = ["${google_sql_database_instance.mysql_instance.private_ip_address}/32"]
}

# Datastream Private Connection using PSC
resource "google_datastream_private_connection" "default" {
  display_name          = var.datastream_psc_name
  location              = var.region
  private_connection_id = var.datastream_psc_name

  psc_interface_config {
    network_attachment = google_compute_network_attachment.ds_to_sql_attachment.id
  }
  depends_on = [
    google_compute_firewall.allow_datastream_psc_to_sql,
    google_project_service.project_services["datastream.googleapis.com"]
  ]
}

# Datastream Connection Profile
resource "google_datastream_connection_profile" "mysql_source_profile" {
  project               = var.project_id
  location              = var.region
  connection_profile_id = "${var.datastream_src_conn_profile_name}-${random_id.suffix.hex}"
  display_name          = "MySQL Source"

  mysql_profile {
    hostname = google_sql_database_instance.mysql_instance.private_ip_address
    port     = 3306
    username = google_sql_user.datastream_user.name
    password = random_password.ds_password.result
  }

  private_connectivity {
    private_connection = google_datastream_private_connection.default.id
  }
  depends_on = [google_datastream_private_connection.default]
}

# Datastream Connection Profile for GCS Destination
resource "google_datastream_connection_profile" "gcs_destination_profile" {
  project               = var.project_id
  location              = var.region
  connection_profile_id = "${var.datastream_dest_conn_profile_name}-${random_id.suffix.hex}"
  display_name          = "GCS Destination"
  gcs_profile {
    bucket    = google_storage_bucket.staging_bucket.name
    root_path = "/"
  }
}

resource "google_datastream_stream" "default" {
  project      = var.project_id
  location     = var.region
  stream_id    = "${var.datastream_name}-${random_id.suffix.hex}"
  display_name = "MySQL to GCS CDC Stream"
  source_config {
    source_connection_profile = google_datastream_connection_profile.mysql_source_profile.id
    mysql_source_config {
      # Note: Dataflow template version '2025-08-19-00_RC00' cannot process data from GTID-based replication.
      # gtid {}
      binary_log_position {}
      # include_objects {
      #   mysql_databases {
      #     database = var.db_name
      #   }
      # }
    }
  }
  destination_config {
    destination_connection_profile = google_datastream_connection_profile.gcs_destination_profile.id
    gcs_destination_config {
      path                   = "/cdc-data"
      file_rotation_mb       = 100
      file_rotation_interval = "60s"
      avro_file_format {}
    }
  }
  backfill_all {}
  depends_on = [
    google_datastream_connection_profile.mysql_source_profile,
    google_datastream_connection_profile.gcs_destination_profile
  ]
}
