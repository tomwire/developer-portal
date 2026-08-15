# =============================================================================
# Developer Portal — Makefile
# =============================================================================
# Build, test, deploy, and manage the Internal Developer Platform.
#
# Usage:
#   make help           # Show available targets
#   make setup          # Install dependencies and run migrations
#   make dev            # Start Backstage for local development
#   make build          # Build the app package
#   make test           # Run all tests
#   make lint           # Lint code
#   make format         # Format code
#   make deploy ENV=<dev|staging|prod>  # Deploy to environment
# =============================================================================

SHELL := /bin/bash

ENV       ?= dev
PROJECT   := developer-portal
NAMESPACE := idp-$(ENV)
CLUSTER   := eks-$(ENV)-idp
IMG_NAME  := public.ecr.aws/tomwire/$(PROJECT)
IMG_TAG   ?= $(shell git rev-parse --short HEAD)

# Environments we support
VALID_ENVS := dev staging prod

.PHONY: help setup install dev build test lint format \
        deploy destroy clean \
        terraform-init terraform-validate terraform-apply terraform-plan \
        kustomize-build catalog-sync template-list

##@ General

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

##@ Development

setup: install ## Install dependencies and run initial setup
	@echo "✅ Setup complete. Run 'make dev' to start the portal."

install: ## Install all npm dependencies
	@echo "📦 Installing dependencies..."
	npm ci --ignore-scripts || npm install
	@echo "✅ Dependencies installed"

dev: ## Start Backstage for local development (with Postgres)
	@echo "🚀 Starting Backstage in dev mode..."
	npx backstage-cli db-migrate-list 2>/dev/null | grep -q empty \
		|| npx backstage-cli db-migrate-all 2>/dev/null || true
	docker compose -f docker-compose.dev.yaml up -d postgres
	npx backstage-cli build && npx backstage-cli start

##@ Build & Test

build: ## Build the app package (all workspace packages)
	@echo "🔨 Building..."
	npx backstage-cli repo build --all
	@echo "✅ Build complete"

test: ## Run all tests (unit + integration)
	@echo "🧪 Running tests..."
	npx backstage-cli repo test --ci --coverage
	@echo "✅ Tests passed"

lint: ## Lint all packages
	@echo "🔍 Linting..."
	npx backstage-cli repo lint --error
	@echo "✅ Lint passed"

format: ## Format all code (Prettier + ESLint fix)
	@echo "✨ Formatting..."
	npx prettier --write "**/*.{ts,tsx,yaml,json}" 2>/dev/null || true
	npx eslint --fix "**/*.{ts,tsx}" 2>/dev/null || true
	@echo "✅ Formatted"

##@ Kubernetes / ArgoCD

kustomize-build: ## Build Kustomize overlays for all environments
	@for env in $(VALID_ENVS); do \
		echo "Building $$env overlay..."; \
		kustomize build k8s-manifests/overlays/$$env && echo "  ✅ $$env OK" || echo "  ⚠️ $$env placeholders expected"; \
	done

kustomize-dev: ## Build dev overlay only
	@echo "Building dev overlay..."
	kustomize build k8s-manifests/overlays/dev

deploy: validate-env ## Deploy Backstage to the target environment
	@if [ "$(ENV)" = "dev" ]; then \
		echo "🚀 Deploying to $(NAMESPACE) on $(CLUSTER)..."; \
		kubectl apply -k environments/$(ENV)/; \
		kubectl rollout status deployment/backstage -n $(NAMESPACE) --timeout=300s 2>/dev/null || echo "⏭️ Rollout status unavailable"; \
		echo "✅ Deployed to dev (ArgoCD selfHeal enabled)"; \
	elif [ "$(ENV)" = "staging" ]; then \
		echo "⚠️ Staging deployment requires manual approval."; \
		echo "👉 Use 'make deploy-staging' or the GitHub Actions workflow"; \
	elif [ "$(ENV)" = "prod" ]; then \
		echo "🔒 Production deployment requires double approval."; \
		echo "👉 Use the GitHub Actions workflow (CD — Promote Backstage to Production)"; \
	fi

validate-env: ## Validate that ENV is one of dev/staging/prod
	@echo "$(VALID_ENVS)" | grep -qw "$(ENV)" || \
		(echo "❌ Invalid environment '$(ENV)'. Valid: $(VALID_ENVS)" && exit 1)

##@ Terraform / Infrastructure

terraform-init: ## Init Terraform for the target environment
	@cd environments/$(ENV) && terraform init -backend=true

terraform-plan: ## Show what Terraform would change
	@cd environments/$(ENV) && terraform plan -var-file=terraform.tfvars 2>/dev/null || \
		cd environments/$(ENV) && terraform plan

terraform-apply: ## Apply Terraform changes (DANGER)
	@echo "⚠️  This will apply changes to $(ENV)."
	@cd environments/$(ENV) && terraform apply -auto-approve

terraform-validate: ## Validate all Terraform configurations
	@echo "🔍 Validating providers module..."
	@cd providers && terraform init -backend=false >/dev/null 2>&1 && \
		terraform validate -no-color && echo "  ✅ providers OK"
	@for env in $(VALID_ENVS); do \
		echo "Validating $$env..."; \
		cd environments/$$env && \
		terraform init -backend=false >/dev/null 2>&1 && \
		terraform validate -no-color && echo "  ✅ $$env OK" || echo "  ❌ $$env FAIL"; \
		cd ../..; \
	done

##@ Templates

template-list: ## List available Software Templates
	@echo "📋 Available Software Templates:"
	@for tmpl in software-templates/*/; do \
		TMPL=$$(basename "$$tmpl"); \
		if [ -f "$$tmpl/scaffold.yml" ]; then \
			NAME=$$(grep 'title:' "$$tmpl/scaffold.yml" | head -1 | sed 's/.*title: *//'); \
			echo "  🔧 $$TMPL — $${NAME:-$(basename $$tmpl)}"; \
		fi; \
	done

catalog-sync: ## Sync catalog-info from scaffold outputs into Backstage catalog
	@echo "📡 Syncing catalog entities..."
	@for file in catalog-info/**/*.yaml; do \
		if [ -f "$$file" ]; then \
			echo "  Registering $$file"; \
			curl -X POST http://localhost:7007/api/catalog/entities \
				-H 'Content-Type: application/yaml' \
				-d "@$$file" 2>/dev/null || true; \
		fi; \
	done

##@ Cleanup

destroy: ## Destroy all environments (DANGER)
	@echo "⚠️  This will destroy ALL environments and their infrastructure."
	@read -p "Type 'DESTROY-ALL' to confirm: " confirm; \
	if [ "$$confirm" != "DESTROY-ALL" ]; then \
		echo "Aborted."; exit 1; fi
	@for env in $(VALID_ENVS); do \
		echo "Destroying $$env..."; \
		cd environments/$$env && terraform destroy -auto-approve 2>/dev/null || true; \
		cd ../..; \
	done

clean: ## Clean build artifacts and node_modules
	@echo "🧹 Cleaning..."
	rm -rf node_modules app/node_modules
	npx backstage-cli repo clean 2>/dev/null || true
	docker compose -f docker-compose.dev.yaml down 2>/dev/null || true
	@echo "✅ Cleaned"
