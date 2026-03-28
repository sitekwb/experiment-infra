# 🔧 experiment-infra

Współdzielony submoduł infrastruktury eksperymentalnej.
Dodawany jako git submodule do każdego repozytorium projektowego.

## Dodanie do projektu

```bash
cd your-project/
git submodule add git@github.com:<username>/experiment-infra.git experiment-infra
git commit -m "Add experiment-infra submodule"
```

## Aktualizacja we wszystkich projektach

```bash
cd your-project/
git submodule update --remote experiment-infra
git commit -m "Update experiment-infra"
```

## Zawartość

```
experiment-infra/
├── infra/          # Terraform (GCP Spot VM)
├── scripts/        # run-on-vm.sh, notify-discord.sh
├── workflow/       # Reusable workflow (called by each project)
└── templates/      # Szablony do skopiowania do projektu
```
