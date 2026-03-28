#!/bin/bash
set -euo pipefail

# setup-experiments.sh
# Run this ONCE in a project repo to add experiment infrastructure.
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/<username>/experiment-infra/main/setup.sh | bash
#   — or —
#   bash experiment-infra/setup.sh
#
# What it does:
# 1. Adds experiment-infra as git submodule (if not present)
# 2. Copies workflow + docker-compose + Dockerfile + experiment.sh templates
# 3. Does NOT overwrite existing files

GH_USERNAME="${GH_USERNAME:-}"  # Set this or it will prompt

if [ -z "$GH_USERNAME" ]; then
  read -p "GitHub username/org: " GH_USERNAME
fi

INFRA_REPO="git@github.com:${GH_USERNAME}/experiment-infra.git"

echo "🔧 Setting up experiment infrastructure..."
echo "   Repo: $INFRA_REPO"
echo ""

# ── 1. Add submodule ────────────────────────────────────────
if [ ! -d "experiment-infra" ]; then
  echo "📦 Adding experiment-infra submodule..."
  git submodule add "$INFRA_REPO" experiment-infra
else
  echo "✅ experiment-infra submodule already exists"
fi

# ── 2. Copy templates (no overwrite) ────────────────────────
copy_if_missing() {
  local src="$1" dst="$2"
  if [ -f "$dst" ]; then
    echo "  ⏭️  $dst already exists, skipping"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  ✅ Created $dst"
  fi
}

echo ""
echo "📋 Copying templates..."

# Detect if this is AgentTutor (web app) or ML project
PROJECT_NAME=$(basename "$(pwd)")
if [ "$PROJECT_NAME" = "AgentTutor" ]; then
  WORKFLOW_SRC="experiment-infra/templates/experiment-agenttutor.yml"
else
  WORKFLOW_SRC="experiment-infra/templates/experiment.yml"
fi

copy_if_missing "experiment-infra/templates/experiment.yml" ".github/workflows/experiment.yml"
copy_if_missing "experiment-infra/templates/docker-compose.experiment.yml" "docker-compose.experiment.yml"
copy_if_missing "experiment-infra/templates/Dockerfile.experiment" "Dockerfile.experiment"
copy_if_missing "experiment-infra/templates/experiment.sh" "experiment.sh"

# ── 3. Remind about the uses: line ──────────────────────────
echo ""
echo "⚠️  IMPORTANT: Edit .github/workflows/experiment.yml"
echo "   Replace the 'uses:' line with:"
echo "   uses: ${GH_USERNAME}/experiment-infra/.github/workflows/run-experiment.yml@main"
echo ""
echo "⚠️  IMPORTANT: Add these GitHub Secrets (Settings → Secrets):"
echo "   GCP_SA_KEY, GCP_PROJECT_ID, DISCORD_WEBHOOK_URL, VM_SSH_PRIVATE_KEY, GH_PAT"
echo ""
echo "✅ Done! Customize docker-compose.experiment.yml and experiment.sh for your project."
