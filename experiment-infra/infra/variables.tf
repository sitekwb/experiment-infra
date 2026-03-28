variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "europe-west1"
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "europe-west1-b"
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-standard-4"
}

variable "gpu_type" {
  description = "GPU accelerator type (empty = no GPU)"
  type        = string
  default     = ""
}

variable "gpu_count" {
  description = "Number of GPUs"
  type        = number
  default     = 0
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 80
}

variable "experiment_id" {
  description = "Unique experiment identifier"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "max_runtime_seconds" {
  description = "Max VM lifetime in seconds (safety net)"
  type        = number
  default     = 14400
}

variable "expose_http" {
  description = "Open port 80/443/8080 for web app testing"
  type        = bool
  default     = false
}
