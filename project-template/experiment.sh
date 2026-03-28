#!/bin/bash
set -euo pipefail

# experiment.sh — Your experiment entrypoint. Adapt to your project.
# Everything written to /app/results/ gets collected.

echo "=== Experiment: $(date -u) ==="
echo "SEED=$SEED EPOCHS=$EPOCHS BATCH_SIZE=$BATCH_SIZE"

# ── Replace with your actual experiment command ──
python train.py \
  --seed "$SEED" \
  --epochs "$EPOCHS" \
  --batch-size "$BATCH_SIZE" \
  --output-dir /app/results

echo "=== Done ==="
