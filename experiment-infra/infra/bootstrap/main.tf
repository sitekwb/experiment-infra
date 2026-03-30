resource "google_storage_bucket" "terraform_state" {
  name                        = var.state_bucket_name
  location                    = var.location
  project                     = var.gcp_project_id
  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = true
  }
}
