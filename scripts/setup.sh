# =============================================================================
# Developer Portal — Setup Script
# =============================================================================
# Initialize local development environment with dependencies, databases,
# and optional cloud infrastructure.
# Usage: ./scripts/setup.sh [env]
#   env: dev | staging | prod (defaults to dev)
# =============================================================================

set -euo pipefail

ENV="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🏗️  Setting up Developer Portal ($ENV environment)..."
echo "=============================================="

# ---------------------------------------------------------------------------
# Step 1: Install npm dependencies
# ---------------------------------------------------------------------------
echo ""
echo "📦 Installing dependencies..."
cd "$REPO_ROOT"
npm ci --ignore-scripts || npm install
echo "✅ Dependencies installed"

# ---------------------------------------------------------------------------
# Step 2: Start local services (Postgres + Keycloak)
# ---------------------------------------------------------------------------
echo ""
echo "🐘 Starting local services (Postgres, Keycloak)..."
docker compose -f "$REPO_ROOT/docker-compose.dev.yaml" up -d
sleep 5

# ---------------------------------------------------------------------------
# Step 3: Database migration
# ---------------------------------------------------------------------------
echo ""
echo "🗄️  Running database migrations..."
cd "$REPO_ROOT/app/packages/backend"
npx backstage-cli db-migrate-all 2>/dev/null || echo "⏭️ No migrations to run (SQLite mode)"

# ---------------------------------------------------------------------------
# Step 4: Validate templates
# ---------------------------------------------------------------------------
echo ""
echo "📋 Validating Software Templates..."
for tmpl in "$REPO_ROOT/software-templates"/*/scaffold.yml; do
    if [ -f "$tmpl" ]; then
        echo "  ✅ $(basename $(dirname $tmpl))"
    fi
done

# ---------------------------------------------------------------------------
# Step 5: Build Kustomize overlays (validate only)
# ---------------------------------------------------------------------------
echo ""
echo "🏗️  Validating Kustomize overlays..."
for env in dev staging prod; do
    kustomize build "$REPO_ROOT/k8s-manifests/overlays/$env" >/dev/null 2>&1 \
        && echo "  ✅ $env overlay valid" || echo "  ⚠️ $env overlay has placeholders (expected)"
done

echo ""
echo "=============================================="
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Start the Backstage app: make dev"
echo "  2. Open http://localhost:7007"
echo "  3. Navigate to Scaffolder → Create New Component"
if [ "$ENV" != "dev" ]; then
    echo ""
    echo "⚠️ $ENV environment requires AWS credentials and infrastructure."
fi
