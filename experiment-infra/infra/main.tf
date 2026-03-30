locals {
  vm_name    = "exp-${var.experiment_id}"
  has_gpu    = var.gpu_type != "" && var.gpu_count > 0
  boot_image = local.has_gpu ? "deeplearning-platform-release/common-gpu-debian-11" : "ubuntu-os-cloud/ubuntu-2204-lts"
}

# ─── Networking ──────────────────────────────────────────────

resource "google_compute_firewall" "experiment_ssh" {
  name    = "allow-ssh-${var.experiment_id}"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_ranges
  target_tags   = ["experiment-vm"]
}

resource "google_compute_firewall" "experiment_http" {
  count   = var.expose_http ? 1 : 0
  name    = "allow-http-${var.experiment_id}"
  network = var.network

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

  attached_disk {
    source      = google_compute_disk.work_disk.id
    device_name = "benchmark-data"
    mode        = "READ_WRITE"
  }

  dynamic "guest_accelerator" {
    for_each = local.has_gpu ? [1] : []
    content {
      type  = var.gpu_type
      count = var.gpu_count
    }
  }

  scheduling {
    provisioning_model          = var.provisioning_model
    preemptible                 = var.provisioning_model == "SPOT"
    instance_termination_action = var.provisioning_model == "SPOT" ? var.instance_termination_action : null
    automatic_restart           = var.provisioning_model == "SPOT" ? false : true
    # SPOT/preemptible requires TERMINATE (cannot use MIGRATE with preemptible).
    on_host_maintenance = (local.has_gpu || var.provisioning_model == "SPOT") ? "TERMINATE" : "MIGRATE"
  }

  # Do not set metadata.startup-script here: it conflicts with metadata_startup_script
  # (same GCE key). GPU/CPU bootstrap is appended at the end of metadata_startup_script.
  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  # Auto-shutdown safety net with periodic idle checks.
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -euo pipefail

    mkdir -p /data
    if ! blkid /dev/disk/by-id/google-benchmark-data; then
      mkfs.ext4 -F /dev/disk/by-id/google-benchmark-data
    fi
    mount -o discard,defaults /dev/disk/by-id/google-benchmark-data /data
    grep -q "google-benchmark-data" /etc/fstab || \
      echo "/dev/disk/by-id/google-benchmark-data /data ext4 discard,defaults,nofail 0 2" >> /etc/fstab
    chown -R ${var.ssh_user}:${var.ssh_user} /data

    cat >/usr/local/bin/auto-shutdown-if-idle.sh <<'EOS'
    #!/usr/bin/env bash
    set -euo pipefail

    STATE_FILE="/var/lib/auto-shutdown-idle-count"
    IDLE_LIMIT_MINUTES="$${IDLE_LIMIT_MINUTES:-240}"
    CHECK_INTERVAL_MINUTES="$${CHECK_INTERVAL_MINUTES:-10}"
    REQUIRED_IDLE_CHECKS=$((IDLE_LIMIT_MINUTES / CHECK_INTERVAL_MINUTES))

    active_users="$(who | awk '$1 != "root" && $1 != "nobody" {count++} END {print count+0}')"
    load_1m="$(awk '{print $1}' /proc/loadavg)"
    is_busy="$(awk -v load="$${load_1m}" 'BEGIN {print (load >= 0.20) ? 1 : 0}')"

    if [ "$${active_users}" -eq 0 ] && [ "$${is_busy}" -eq 0 ]; then
      current=0
      if [ -f "$${STATE_FILE}" ]; then
        current="$(cat "$${STATE_FILE}" 2>/dev/null || echo 0)"
      fi
      current="$((current + 1))"
      echo "$${current}" > "$${STATE_FILE}"

      if [ "$${current}" -ge "$${REQUIRED_IDLE_CHECKS}" ]; then
        logger -t auto-shutdown "Idle limit reached ($${IDLE_LIMIT_MINUTES}m). Shutting down."
        shutdown -h now
      fi
    else
      echo 0 > "$${STATE_FILE}"
    fi
    EOS
    chmod +x /usr/local/bin/auto-shutdown-if-idle.sh

    cat >/etc/systemd/system/auto-shutdown-idle.service <<'EOS'
    [Unit]
    Description=Shutdown VM after sustained inactivity

    [Service]
    Type=oneshot
    Environment=IDLE_LIMIT_MINUTES=${var.max_idle_hours * 60}
    Environment=CHECK_INTERVAL_MINUTES=10
    ExecStart=/usr/local/bin/auto-shutdown-if-idle.sh
    EOS

    cat >/etc/systemd/system/auto-shutdown-idle.timer <<'EOS'
    [Unit]
    Description=Run inactivity shutdown check every 10 minutes

    [Timer]
    OnBootSec=10m
    OnUnitActiveSec=10m
    Persistent=true

    [Install]
    WantedBy=timers.target
    EOS

    systemctl daemon-reload
    systemctl enable --now auto-shutdown-idle.timer

    (sleep ${var.max_runtime_seconds} && shutdown -h now) &

    ${local.has_gpu ? file("${path.module}/startup-gpu.sh") : file("${path.module}/startup-cpu.sh")}
  EOF

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
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

output "data_disk_name" {
  value = google_compute_disk.work_disk.name
}

resource "google_compute_disk" "work_disk" {
  name = "${local.vm_name}-data"
  type = var.data_disk_type
  size = var.data_disk_size_gb
  zone = var.gcp_zone
}
