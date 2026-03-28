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
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]+-[a-z]$", var.gcp_zone))
    error_message = "gcp_zone must be a valid GCP zone (e.g., europe-west1-b)."
  }
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
  description = "Number of GPUs (0 or 1)"
  type        = number
  default     = 0
  validation {
    condition     = contains([0, 1, 2, 4, 8], var.gpu_count)
    error_message = "gpu_count must be 0, 1, 2, 4, or 8."
  }
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 80
}

variable "experiment_id" {
  description = "Unique experiment identifier"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.experiment_id))
    error_message = "experiment_id must be lowercase alphanumeric with hyphens, max 63 chars."
  }
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

variable "allowed_ssh_ranges" {
  description = "CIDR ranges allowed to SSH into experiment VMs. Default is open; restrict in production (e.g., use 35.235.240.0/20 for GCP IAP)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
