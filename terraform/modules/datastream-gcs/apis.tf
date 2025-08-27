# Enable required APIs for the project
resource "google_project_service" "project_services" {
  for_each = toset([
    "serviceusage.googleapis.com",
    "servicenetworking.googleapis.com",
    "compute.googleapis.com",
    "sqladmin.googleapis.com",
    "datastream.googleapis.com",
    "storage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "pubsub.googleapis.com",
    "dns.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}
