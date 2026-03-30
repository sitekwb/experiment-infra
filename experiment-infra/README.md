# experiment-infra package

Shared infrastructure package consumed by benchmark projects as a git
submodule.

## Directory layout

```
experiment-infra/
├── infra/          # Terraform for GCP experiment VM
├── scripts/        # run-on-vm.sh, notify-discord.sh
└── templates/      # reusable workflow and container templates
```

## Terraform usage

```bash
cd experiment-infra/infra
terraform init
terraform validate
terraform plan \
  -var="gcp_project_id=<your-project>" \
  -var="experiment_id=<experiment-id>" \
  -var="ssh_public_key=<your-public-key>"
```

## Generic module contract

Required variables:
- `gcp_project_id`
- `experiment_id`
- `ssh_public_key`

Commonly tuned variables:
- Runtime and scheduling: `provisioning_model`, `instance_termination_action`, `max_runtime_seconds`, `max_idle_hours`
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

- Do not commit `.terraform/`, `*.tfstate*`, or real `*.tfvars`.
- Keep sample values in `*.tfvars.example` only.
- Commit `.terraform.lock.hcl` to pin provider versions across environments.
