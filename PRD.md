# PRD: Terraform Infrastructure for Datastream, Dataflow, and BigQuery Analytics Pipeline

## 1. Overview

### 1.1. Objective
To provision a scalable, real-time data analytics pipeline on Google Cloud Platform using Infrastructure as Code (IaC). This project will automate the deployment of a Change Data Capture (CDC) system that streams data from a Cloud SQL for MySQL source to BigQuery, using Cloud Storage as an intermediary staging area and Dataflow for processing. The entire infrastructure will be managed by Terraform.

### 1.2. Background
This project is an evolution of the [`gcp-datastream-cdc-data-pipeline` project](https://github.com/ksmin23/gcp-datastream-cdc-data-pipeline). While the original project demonstrated a direct Datastream-to-BigQuery replication, this implementation introduces a more robust and flexible architecture by incorporating a Dataflow processing layer. This aligns with the official Google Cloud reference architecture for enriching and transforming CDC data before it lands in the final analytics warehouse.

Reference Architecture: [Implementing Datastream and Dataflow for real-time analytics](https://cloud.google.com/datastream/docs/implementing-datastream-dataflow-analytics)

## 2. Functional Requirements

### 2.1. Core Data Pipeline Components
The Terraform configuration must provision and configure the following GCP services to work in concert:

| Component | Service | Requirement |
| :--- | :--- | :--- |
| **Data Source** | Cloud SQL for MySQL | A Cloud SQL instance, accessible only via a private network (no public IP), to act as the transactional database source. Must have an `rdsadmin` user for management and a dedicated `datastream` user for CDC. |
| **Staging Area** | Google Cloud Storage (GCS) | A GCS bucket to receive the raw, unprocessed CDC events written by Datastream. |
| **Replication** | Datastream | A stream configured to capture changes from the Cloud SQL source and write them to the GCS staging bucket. |
| **Notification** | Pub/Sub | A Pub/Sub topic and subscription to notify Dataflow in real-time when new CDC files are written to the GCS bucket. |
| **Processing** | Dataflow | A streaming Dataflow job, based on the Google-provided "Datastream to BigQuery" template, that is triggered by Pub/Sub notifications to process new data from GCS. Must include a **Dead-Letter Queue** (GCS bucket) to capture and store data that fails during processing. |
| **Destination** | BigQuery | A BigQuery dataset and tables to store the final, processed data ready for analytics. |
| **Networking** | VPC, Subnets, PSC, Cloud NAT | Secure private networking using a custom VPC. A **Datastream Private Connection (using PSC)** enables secure communication to the Cloud SQL instance's private IP. A separate **PSC Endpoint** provides stable in-VPC access for other clients. A **Cloud NAT** gateway provides internet access for private resources like Dataflow workers. |

### 2.2. Key Architectural Changes from Predecessor
- **Datastream Destination:** The Datastream stream's destination must be configured to a **Google Cloud Storage bucket**, not directly to BigQuery.
- **Introduction of Dataflow:** A Dataflow streaming job will be provisioned to read from the GCS bucket, apply transformations, and load data into BigQuery.
- **Event-Driven Triggering:** The pipeline will be event-driven. Pub/Sub notifications from GCS will trigger Dataflow processing, ensuring low latency between data arrival and processing.
- **Secure Database Connectivity**: Datastream will connect to Cloud SQL's **private IP address** via a **Datastream Private Connection (PSC)**, eliminating the need for a Private DNS Zone for this purpose.

## 3. Non-Functional Requirements

### 3.1. Infrastructure as Code (IaC)
- The entire infrastructure must be defined in HashiCorp Configuration Language (HCL) for Terraform.
- The code must be modular and reusable.
- A GCS bucket must be used as the backend for storing the Terraform state file (`terraform.tfstate`), ensuring state is managed remotely and securely.

### 3.2. Security
- **Principle of Least Privilege:** All service accounts must be granted only the IAM permissions necessary for their function.
    - The `datastream` database user should have the minimal required permissions for replication (`REPLICATION SLAVE`, `SELECT`, `REPLICATION CLIENT`).
    - The Dataflow worker service account must have roles like `roles/dataflow.worker`, `roles/pubsub.subscriber`, `roles/storage.objectAdmin`, and `roles/bigquery.dataEditor`.
- **Private Networking:** All communication between GCP services must occur over the private network. The Cloud SQL instance must have its public IP disabled. Datastream's connection to Cloud SQL must be via its private IP through a PSC-based private connection.
- **Secrets Management:** Database credentials for the `rdsadmin` and `datastream` users should be generated at runtime by Terraform and passed securely.

### 3.3. Configurability
- The Terraform project must be highly configurable through variables (`.tfvars`).
- Key parameters such as `project_id`, `region`, instance names, bucket names, and dataset names must be externalized from the core logic.
- Performance and cost-related parameters (e.g., Cloud SQL `db_tier`, Dataflow `machine_type`) must be configurable.

### 3.4. Naming Conventions
- All resources should follow a consistent naming convention to ensure clarity and manageability.
- **Recommended Format**: `{prefix}-{environment}-{resource_name}-{suffix}` (e.g., `ds-dev-sql-instance-main`).

### 3.5. Monitoring and Alerting
- Basic monitoring and alerting must be configured to ensure pipeline reliability.
- **Dataflow Job Lag:** A Cloud Monitoring alert should be created to trigger a notification (e.g., via Pub/Sub or Email) if the system lag of the Dataflow streaming job exceeds 5 minutes.
- **Datastream Latency:** A Cloud Monitoring alert should be created to trigger a notification if the data freshness latency of the Datastream stream exceeds 10 minutes.

## 4. Terraform Structure & Implementation Details

### 4.1. Component Configuration Details

#### 4.1.1. Cloud SQL for MySQL
- **MySQL Version:** `MYSQL_8_0`
- **Tier:** Must be a configurable variable (e.g., `db-n1-standard-1`).
- **CDC Flags:** The instance must be configured with the necessary flags for binary logging (`log_bin`, `binlog_format=ROW`, etc.) to support Datastream.
- **PSC Enabled**: The instance must be configured to allow Private Service Connect.
- **Database Users**: An `rdsadmin` user and a `datastream` user must be created with unique, randomly generated passwords.

#### 4.1.2. Dataflow (from Template)
- **Template:** The project will use the Google-provided "Datastream to BigQuery" template.
- **Machine Type:** Must be a configurable variable (e.g., `n1-standard-1`).
- **Input:** The Dataflow job will be configured to use a Pub/Sub subscription for file notifications.
- **Dead-Letter Queue:** The job must be configured with a GCS path for its dead-letter queue.

#### 4.1.3. BigQuery
- **Schema Management:** BigQuery tables are allowed to be created dynamically by the Dataflow job.

### 4.2. Required Resources (High-Level)
- `google_sql_database_instance`
- `google_sql_user` (for `rdsadmin` and `datastream`)
- `google_storage_bucket` (for staging and dead-letter queue)
- `google_pubsub_topic`
- `google_storage_notification`
- `google_pubsub_subscription`
- `google_datastream_private_connection`
- `google_datastream_connection_profile`
- `google_datastream_stream`
- `google_dataflow_job`
- `google_bigquery_dataset`
- `google_project_iam_member` / `google_service_account`
- `google_dns_managed_zone`
- `google_compute_forwarding_rule` (for PSC)
- `google_dns_record_set`
- `google_compute_router`
- `google_compute_router_nat`
- `google_monitoring_alert_policy`

## 5. Deliverables

1.  A complete set of Terraform files (`.tf`) to provision the entire pipeline.
2.  A `variables.tf` file defining all configurable parameters.
3.  An example `terraform.tfvars.example` file showing users how to configure the project with sensible defaults.
4.  A `README.md` file with detailed instructions on how to initialize, plan, and apply the Terraform configuration.
5.  **Required Outputs**: The root Terraform module must output the following values after a successful `apply` for operational purposes:
    -   Cloud SQL Instance Name
    -   Cloud SQL Instance Private IP
    -   Admin User Name (`rdsadmin`)
    -   Admin User Password (marked as sensitive)
    -   Datastream User Name (`datastream`)
    -   Datastream User Password (marked as sensitive)
    -   Datastream Stream Name
    -   GCS Staging Bucket Name

## 6. Out of Scope

-   Custom Dataflow pipeline code.
-   CI/CD automation for deploying the Terraform infrastructure.
