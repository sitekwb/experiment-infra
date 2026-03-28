locals {
  vm_name    = "exp-${var.experiment_id}"
  has_gpu    = var.gpu_type != "" && var.gpu_count > 0
  boot_image = local.has_gpu ? "deeplearning-platform-release/common-gpu-debian-11" : "cos-cloud/cos-stable"
}

# ─── Networking ──────────────────────────────────────────────

resource "google_compute_firewall" "experiment_ssh" {
  name    = "allow-ssh-${var.experiment_id}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["experiment-vm"]
}

resource "google_compute_firewall" "experiment_http" {
  count   = var.expose_http ? 1 : 0
  name    = "allow-http-${var.experiment_id}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["experiment-vm"]
}

# ─── VM Instance ─────────────────────────────────────────────

resource "google_compute_instance" "experiment" {
  name         = local.vm_name
  machine_type = var.machine_type
  zone         = var.gcp_zone

  tags = ["experiment-vm"]

  boot_disk {
    initialize_params {
      image = local.boot_image
      size  = var.disk_size_gb
      type  = "pd-ssd"
    }
  }

  dynamic "guest_accelerator" {
    for_each = local.has_gpu ? [1] : []
    content {
      type  = var.gpu_type
      count = var.gpu_count
    }
  }

  scheduling {
    provisioning_model  = "SPOT"
    preemptible         = true
    automatic_restart   = false
    on_host_maintenance = local.has_gpu ? "TERMINATE" : "MIGRATE"
  }

  metadata = {
    ssh-keys = "runner:${var.ssh_public_key}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Auto-shutdown safety net
    (sleep ${var.max_runtime_seconds} && shutdown -h now) &

    ${local.has_gpu ? file("${path.module}/startup-gpu.sh") : ""}
  EOF

  network_interface {
    network = "default"
    access_config {}
  }

  lifecycle {
    ignore_changes = [scheduling]
  }
}

# ─── Outputs ─────────────────────────────────────────────────

output "vm_ip" {
  value = google_compute_instance.experiment.network_interface[0].access_config[0].nat_ip
}

output "vm_name" {
  value = google_compute_instance.experiment.name
}

output "vm_zone" {
  value = var.gcp_zone
}
