#!/bin/bash
set -euo pipefail

# run-on-vm.sh — Executed on the GCP VM via SSH
# Expects: ~/project/ (cloned repo), ~/experiment-config.yml

EXTRA_ARGS="${1:-}"
PROJECT_DIR="$HOME/project"
COMPOSE_FILE="docker-compose.experiment.yml"

cd "$PROJECT_DIR"

echo "========================================="
echo "  Project:  $(basename $PROJECT_DIR)"
echo "  Started:  $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "  Machine:  $(uname -m), $(nproc) cores, $(free -h | awk '/Mem:/{print $2}') RAM"
echo "  GPU:      $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo 'none')"
echo "========================================="

mkdir -p results

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "ERROR: $COMPOSE_FILE not found in project root"
  echo "Add docker-compose.experiment.yml to your repo."
  exit 1
fi

echo "Building images..."
docker compose -f "$COMPOSE_FILE" build

echo "Starting experiment..."
docker compose -f "$COMPOSE_FILE" up \
  --abort-on-container-exit \
  --exit-code-from experiment \
  2>&1 | tee results/experiment-stdout.log

EXIT_CODE=${PIPESTATUS[0]}

echo "========================================="
echo "  Finished: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "  Exit:     $EXIT_CODE"
echo "  Results:  $(ls results/ | wc -l) files"
echo "========================================="
ls -la results/

exit $EXIT_CODE
