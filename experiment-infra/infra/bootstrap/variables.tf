variable "gcp_project_id" {
  description = "GCP project ID where the Terraform state bucket will be created"
  type        = string
}

variable "gcp_region" {
  description = "Default region for the provider (bucket location uses var.location)"
  type        = string
  default     = "europe-west1"
}

variable "state_bucket_name" {
  description = "Globally unique GCS bucket name for Terraform state (e.g. my-project-tfstate)"
  type        = string
}

variable "location" {
  description = "GCS bucket location (region such as europe-west1, or multi-region EU)"
  type        = string
  default     = "EU"
}
