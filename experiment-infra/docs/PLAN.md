# Plan wdrożenia: Experiment Infrastructure (submodule)

## Architektura

```
Każde repo projektowe:
├── .github/workflows/experiment.yml  ← ~30 linii, workflow_dispatch
├── docker-compose.experiment.yml     ← definicja kontenera
├── Dockerfile.experiment             ← środowisko
├── experiment.sh                     ← "co policzyć"
└── experiment-infra/                 ← GIT SUBMODULE
    ├── infra/          (Terraform)
    ├── scripts/        (run-on-vm.sh, notify-discord.sh)
    ├── .github/workflows/run-experiment.yml  (reusable workflow)
    └── templates/      (szablony do skopiowania)
```

```
iPhone (Claude Code / GitHub Mobile)
  → workflow_dispatch w REPOZYTORIUM PROJEKTU
    → calls reusable workflow z experiment-infra
      → terraform apply (GCP Spot VM)
      → git clone TEGO PROJEKTU na VM
      → docker compose up
      → scp results → GitHub artifact + branch
      → Discord webhook
      → terraform destroy (ALWAYS)
```

## Zalety submodule vs osobne repo

1. Claude Code pracuje w kontekście projektu → od razu `gh workflow run`
2. Zmiany kodu + odpalenie = jeden flow, zero przeskakiwania
3. Każdy projekt ma SWÓJ workflow, SWOJE dropdown w GitHub UI
4. Infra współdzielona — update submodule = update we wszystkich
5. Secrets per-repo (można różne GCP projekty per projekt)

## 7 kroków wdrożenia

### Krok 1: Stwórz repo experiment-infra (20 min)

```bash
mkdir experiment-infra && cd experiment-infra
git init
# ← skopiuj zawartość z paczki experiment-infra/
git add . && git commit -m "Initial experiment infrastructure"
gh repo create experiment-infra --private --push
```

### Krok 2: GCP Setup (45 min)

1. Projekt GCP: `pw-experiments`
2. APIs: Compute Engine, Cloud Storage
3. Service Account: `experiment-runner@...`
   → Role: Compute Admin, Storage Admin
4. Pobierz JSON key
5. GCS bucket: `gs://pw-experiment-tf-state`
6. Budget Alert: $100/miesiąc

### Krok 3: GitHub Secrets (20 min)

Dodaj do KAŻDEGO repozytorium projektowego (albo na poziomie org):

| Secret | Wartość |
|--------|---------|
| GCP_SA_KEY | JSON klucza SA |
| GCP_PROJECT_ID | ID projektu GCP |
| DISCORD_WEBHOOK_URL | Webhook Discord |
| VM_SSH_PRIVATE_KEY | Klucz SSH (ed25519) |
| GH_PAT | Personal Access Token (repo scope) |

Tip: jeśli masz GitHub Organization, ustaw secrets na poziomie org
→ automatycznie dostępne we wszystkich repo.

### Krok 4: Discord webhook (10 min)

Serwer → #experiments → Integrations → Webhook → URL → Secret

### Krok 5: SSH keypair (5 min)

```bash
ssh-keygen -t ed25519 -f ~/.ssh/experiment-runner -N ""
```

### Krok 6: Dodaj infra do pierwszego projektu (15 min)

```bash
cd local-legal-acts/   # zacznij od najmniejszego
bash <(curl -sL https://raw.githubusercontent.com/<user>/experiment-infra/main/setup.sh)
# Albo ręcznie:
git submodule add git@github.com:<user>/experiment-infra.git experiment-infra
cp experiment-infra/templates/* .   # i popraw paths
```

Edytuj `.github/workflows/experiment.yml`:
```yaml
uses: <username>/experiment-infra/.github/workflows/run-experiment.yml@main
```

Dostosuj `experiment.sh` do projektu.

### Krok 7: Test (15 min)

```bash
# Z Claude Code na iPhone:
gh workflow run experiment.yml \
  -f machine_type=e2-standard-4 \
  -f gpu=none \
  -f max_runtime_minutes=30

gh run watch
```

## Rollout kolejność

| Kolejność | Projekt | Dlaczego |
|-----------|---------|----------|
| 1 | local-legal-acts | Mały compute, szybki test, brak GPU |
| 2 | Genomic-publications-agent | Bez GPU, agentowy (API calls) |
| 3 | moral-machines | Wymaga GPU — test GPU path |
| 4 | bio-variant-prioritization | GPU + dłuższe runy |
| 5 | Climate-human-rights-predictor-agent | GPU + duże dane |
| 6 | AgentTutor | Osobny workflow (deploy-test) |

## Koszty

| Typ | Spot $/h | 4h run |
|-----|----------|--------|
| e2-standard-4 (CPU) | ~$0.04 | ~$0.16 |
| n1-standard-8 + T4 | ~$0.35 | ~$1.40 |
| n1-standard-8 + A100 | ~$1.20 | ~$4.80 |

Budget: $100/mies = ~70 runów z GPU lub ~600 bez GPU.

## Aktualizacja infra we wszystkich projektach

```bash
# W każdym repo:
git submodule update --remote experiment-infra
git add experiment-infra
git commit -m "Update experiment-infra"
```

Albo jednym skryptem:
```bash
for repo in local-legal-acts Genomic-publications-agent Climate-human-rights-predictor-agent moral-machines bio-variant-prioritization AgentTutor; do
  cd ~/$repo
  git submodule update --remote experiment-infra
  git add experiment-infra && git commit -m "Update experiment-infra" && git push
  cd ..
done
```
