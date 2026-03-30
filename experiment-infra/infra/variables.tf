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

variable "provisioning_model" {
  description = "Instance provisioning model (SPOT or STANDARD)"
  type        = string
  default     = "SPOT"
}

variable "instance_termination_action" {
  description = "Termination action for SPOT VMs (STOP or DELETE)"
  type        = string
  default     = "STOP"
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

variable "data_disk_size_gb" {
  description = "Persistent data disk size in GB"
  type        = number
  default     = 200
}

variable "data_disk_type" {
  description = "Persistent data disk type"
  type        = string
  default     = "pd-ssd"
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

variable "ssh_user" {
  description = "SSH username configured on VM"
  type        = string
  default     = "runner"
}

variable "network" {
  description = "VPC network name"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Optional VPC subnetwork name"
  type        = string
  default     = null
}

variable "max_idle_hours" {
  description = "Shut down the VM after this many consecutive idle hours (no non-root SSH sessions, loadavg 1m < 0.2; checked every 10 minutes)."
  type        = number
  default     = 1
}

variable "no_download_shutdown_enabled" {
  description = "Install a timer that shuts down the VM when download_data.sh is not running (after boot grace). Use false if you need the VM up without downloads."
  type        = bool
  default     = true
}

variable "no_download_boot_grace_minutes" {
  description = "Minutes after boot before evaluating no-download shutdown (allows systemd/tmux to start download_data.sh)."
  type        = number
  default     = 25
}

variable "no_download_required_checks" {
  description = "Consecutive timer intervals (10 minutes each) with no download_data.sh before shutdown."
  type        = number
  default     = 1
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
