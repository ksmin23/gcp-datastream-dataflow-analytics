resource "random_id" "id" {
  byte_length = 6
  keepers = {
    project_id = var.project_id
    region     = var.region
  }
}