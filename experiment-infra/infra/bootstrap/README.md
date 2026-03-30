# Bootstrap: Terraform state bucket (GCS)

Run this **once per GCP project** (or when you need a dedicated state bucket). It creates a GCS bucket with **versioning** enabled for use as the remote backend of the parent [`../`](..) Terraform module.

The main [`../providers.tf`](../providers.tf) uses `backend "gcs" {}`. You must pass `bucket` and `prefix` at `terraform init` (see [`../backend.hcl.example`](../backend.hcl.example)).

## Prerequisites

- [Terraform](https://www.terraform.io/) >= 1.5
- [Google Cloud SDK](https://cloud.google.com/sdk) authenticated (`gcloud auth application-default login` or a service account with permission to create buckets)
- IAM: account needs `roles/storage.admin` (or equivalent) on the project to create the bucket

## Usage

```bash
cd experiment-infra/experiment-infra/infra/bootstrap
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: gcp_project_id, state_bucket_name (globally unique)

terraform init
terraform apply
```

Copy the output `bucket_name` into `../backend.hcl` (from `../backend.hcl.example`), then:

```bash
cd ..
cp backend.hcl.example backend.hcl
# Edit backend.hcl: set bucket = "<output bucket_name>", adjust prefix if needed

terraform init -backend-config=backend.hcl
terraform plan -var-file=your.tfvars
```

## State for this bootstrap module

This directory uses a **local** `terraform.tfstate` file (see `backend "local"` in `providers.tf`). Keep it in a safe place or use remote state for bootstrap only if your org requires it. The important production state for experiment VMs lives in the **GCS bucket** after you configure the parent module.

## IAM for Terraform runs

Principals that run `terraform plan` / `apply` on the main infra module need to read and write objects in the state bucket, e.g.:

- `roles/storage.objectAdmin` on the bucket, or
- `roles/storage.objectUser` if your policy allows state locking (GCS backend uses the same bucket for state and locking)

## Migrating existing local state

If you previously used a local `terraform.tfstate` in `../`, run:

```bash
cd ..
terraform init -backend-config=backend.hcl -migrate-state
```
