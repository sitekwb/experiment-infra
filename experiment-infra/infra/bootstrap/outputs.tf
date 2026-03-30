output "bucket_name" {
  description = "GCS bucket name — use this as `bucket` in ../backend.hcl for the main infra module"
  value       = google_storage_bucket.terraform_state.name
}

output "bucket_url" {
  description = "gs:// URL for the state bucket"
  value       = google_storage_bucket.terraform_state.url
}
