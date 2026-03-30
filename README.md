# experiment-infra

Canonical, generic infrastructure submodule for benchmark experiments.

All Terraform and experiment infra logic lives here. Consumer repositories
should keep only the submodule pointer and usage instructions. The Terraform
module is parameterized to support different experiment profiles (CPU/GPU,
networking, runtime limits) across multiple projects/modules.

## Canonical workflow

```bash
# in consumer repository
git submodule update --init --recursive
cd experiment-infra/experiment-infra/infra
terraform init
terraform validate
terraform plan -var="gcp_project_id=<your-project>" -var="experiment_id=<id>" -var="ssh_public_key=<pubkey>"
```

## Team model

1. Make infra changes in this repository (`experiment-infra`).
2. Commit and merge in this repository first.
3. In consumer repository, update submodule pointer with:

```bash
git submodule update --remote experiment-infra
```

4. Commit only the submodule pointer bump in the consumer repository.