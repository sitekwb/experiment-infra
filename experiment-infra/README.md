# experiment-infra package

Shared infrastructure package consumed by benchmark projects as a git
submodule.

## Directory layout

```
experiment-infra/
├── infra/              # Terraform for GCP experiment VM (remote state in GCS)
│   ├── bootstrap/    # One-time: create versioned GCS bucket for Terraform state
│   ├── backend.hcl.example
│   └── ...
├── scripts/            # run-on-vm.sh, notify-discord.sh
└── templates/          # reusable workflow and container templates
```

## Terraform usage

Remote state is stored in **Google Cloud Storage**. **Once per GCP project**, create the bucket:

```bash
cd infra/bootstrap
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — gcp_project_id, state_bucket_name (globally unique)
terraform init
terraform apply
```

Then configure the main module and run plan/apply:

```bash
cd ..
cp backend.hcl.example backend.hcl
# Edit backend.hcl — bucket (from bootstrap output), prefix

terraform init -backend-config=backend.hcl
terraform validate
terraform plan \
  -var="gcp_project_id=<your-project>" \
  -var="experiment_id=<experiment-id>" \
  -var="ssh_public_key=<your-public-key>"
```

See [`infra/bootstrap/README.md`](infra/bootstrap/README.md) for IAM, migrating existing local state, and details.

## Generic module contract

Required variables:
- `gcp_project_id`
- `experiment_id`
- `ssh_public_key`

Commonly tuned variables:
- Runtime and scheduling: `provisioning_model`, `instance_termination_action`, `max_runtime_seconds`, `max_idle_hours`, `no_download_shutdown_enabled`, `no_download_boot_grace_minutes`, `no_download_required_checks`
- Compute profile: `machine_type`, `gpu_type`, `gpu_count`
- Storage profile: `disk_size_gb`, `data_disk_size_gb`, `data_disk_type`
- Network and access: `network`, `subnetwork`, `allowed_ssh_ranges`

### CPU profile example

```bash
terraform plan \
  -var="gcp_project_id=my-project" \
  -var="experiment_id=exp-cpu" \
  -var="ssh_public_key=ssh-ed25519 AAAA... user@host" \
  -var="machine_type=e2-standard-4" \
  -var="gpu_type=" \
  -var="gpu_count=0"
```

### GPU profile example

```bash
terraform plan \
  -var="gcp_project_id=my-project" \
  -var="experiment_id=exp-gpu" \
  -var="ssh_public_key=ssh-ed25519 AAAA... user@host" \
  -var="machine_type=g2-standard-8" \
  -var="gpu_type=nvidia-l4" \
  -var="gpu_count=1"
```

## Notes

- Do not commit `.terraform/`, `*.tfstate*`, real `*.tfvars`, or `backend.hcl` (use `backend.hcl.example`).
- Keep sample values in `*.tfvars.example` only.
- Commit `.terraform.lock.hcl` to pin provider versions across environments.
