# =============================================================================
# Developer Portal — Destroy Script
# =============================================================================
# Tear down all environments and their infrastructure.
# DANGER: This will destroy ALL resources in the target environment(s).
# Usage: ./scripts/destroy.sh [env]
#   env: dev | staging | prod | all (defaults to dev)
# =============================================================================

set -euo pipefail

TARGET="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "⚠️  WARNING: This will destroy infrastructure!"
echo "=============================================="
echo "Target: $TARGET"
echo ""
read -p "Type 'DESTROY-ALL' to confirm: " confirm
if [ "$confirm" != "DESTROY-ALL" ]; then
    echo "Aborted."
    exit 0
fi

# ---------------------------------------------------------------------------
# Destroy environments
# ---------------------------------------------------------------------------
for env in $(echo "$TARGET" | tr ',' ' '); do
    if [ "$env" = "all" ]; then
        envs="dev staging prod"
    else
        envs="$env"
    fi

    for env_name in $envs; do
        echo ""
        echo "🗑️  Destroying $env_name environment..."
        cd "$REPO_ROOT/environments/$env_name" || continue
        terraform destroy -auto-approve 2>/dev/null || echo "⏭️ No state found for $env_name (skip)"
    done
done

# ---------------------------------------------------------------------------
# Cleanup local services
# ---------------------------------------------------------------------------
echo ""
echo "🧹 Cleaning up local services..."
docker compose -f "$REPO_ROOT/docker-compose.dev.yaml" down 2>/dev/null || true
cd "$REPO_ROOT" && npm run clean 2>/dev/null || true

echo ""
echo "=============================================="
echo "✅ Cleanup complete. Resources destroyed."
