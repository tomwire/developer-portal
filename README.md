# 🏗️ Developer Portal — Internal Developer Platform

_A self-service developer portal built with [Backstage](https://backstage.io) that eliminates boilerplate and accelerates development through automated Software Templates, GitOps-powered delivery, and standardized tooling._

> **Portfolio Project 4 of 4** — Demonstrates platform engineering maturity, automated developer onboarding, and enterprise-grade developer experience.

---

## 📚 Table of Contents

- [Architecture](#architecture)
- [What It Does](#what-it-does)
- [Software Templates](#software-templates)
- [Getting Started](#getting-started)
- [Directory Layout](#directory-layout)
- [CI/CD Pipeline](#cicd-pipeline)
- [ArgoCD Integration](#argocd-integration)
- [Infrastructure as Code](#infrastructure-as-code)
- [Drift Detection](#drift-detection)
- [Templates Reference](#templates-reference)
- [Contributing](#contributing)

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Developer Portal                        │
│                     (Backstage App)                          │
│                                                             │
│  ┌──────────────┐  ┌───────────────┐  ┌──────────────────┐ │
│  │ Software      │  │ Catalog        │  │ Scaffolder       │ │
│  │ Templates     │  │ (Entity Graph) │  │ Actions          │ │
│  └──────┬───────┘  └───────────────┘  └────────┬─────────┘ │
│         │                                       │            │
│         ▼                                       ▼            │
│  ┌──────────────┐                    ┌──────────────────────┐ │
│  │ Git Repo      │                    │ Output Artifacts     │ │
│  │ Creation      │                    │ (CI/CD, K8s, Infra)  │ │
│  └──────┬───────┘                    └──────────┬───────────┘ │
│         │                                       │            │
└─────────┼───────────────────────────────────────┼────────────┘
          │                                       │
          ▼                                       ▼
┌─────────────────┐                 ┌─────────────────────────┐
│  Git (GitHub)   │                 │  ArgoCD (GitOps)        │
│                 │                 │                         │
│  New repos      │  ← sync →       │ Dev/Staging/Prod NS     │
│  CI/CD pipelines│                 │ Kustomize overlays      │
└────────┬────────┘                 └───────────┬─────────────┘
         │                                     │
         ▼                                     ▼
┌─────────────────┐                 ┌─────────────────────────┐
│  GitHub Actions │                 │  EKS Kubernetes         │
│                 │                 │                         │
│  Build/Scan     │                 │  Backstage instance     │
│  Lint/Deploy    │                 │  Scaffolded services    │
└─────────────────┘                 └─────────────────────────┘
```

---

## ✨ What It Does

The Developer Portal is a **platform engineering product** that provides:

### 🚀 Self-Service Service Scaffolding

Developers click **"Create New Service"** in the portal and select a template. Within seconds, they receive:

- A new Git repository pre-configured with CI/CD
- Production-ready Dockerfile with multi-stage builds
- GitHub Actions workflows for build, test, scan, and deploy
- Kubernetes manifests (Deployment, Service, HPA, NetworkPolicy)
- Terraform module for infrastructure provisioning
- OpenAPI specification
- README with usage instructions

### 🔧 Standardized Golden Path

Every scaffolded service follows the same conventions:

| Element | Specification |
|---------|--------------|
| **Language** | Node.js 20 LTS or Go 1.22+ |
| **Container** | Distroless or Alpine, non-root user |
| **Health Check** | `/healthz` (readiness) + `/readyz` (liveness) |
| **Observability** | OpenTelemetry auto-instrumentation |
| **CI/CD** | GitHub Actions → ECR → ArgoCD sync |
| **Infra** | Terraform with shared modules |
| **Testing** | Jest (JS) / Ginkgo (Go), coverage ≥ 80% |

### 🔄 GitOps-Powered Delivery

Scaffolded services are deployed through the same ArgoCD GitOps pipeline used by the Backstage app:

1. Developer scaffolds service → repo created
2. GitHub Actions builds, tests, scans, and pushes to ECR
3. ArgoCD detects new manifest in repo → auto-syncs to dev
4. Promotion gates (manual approval) for staging and production
5. Continuous drift detection ensures cluster state matches Git

---

## 📦 Software Templates

Templates are the heart of the portal — declarative YAML specs that define:

1. **Input form** — what the developer fills out
2. **Template steps** — how scaffolding actions execute
3. **Output artifacts** — repos, URLs, and catalog entries created

### Available Templates

| Template | Description | Outputs |
|----------|-------------|---------|
| **Node.js Microservice** | Full-stack API with TypeScript, Prisma, OpenAPI | Repo, CI/CD, K8s manifests, Terraform module |
| **React Frontend** | SPA with Vite, React Query, Storybook | Repo, CI/CD, K8s manifests |
| **Go Service** | Go microservice with gRPC, protobuf | Repo, CI/CD, K8s manifests |
| **Terraform Module** | Shared infrastructure module | Repo, Terraform registry ready |
| **Shared Library** | Reusable TypeScript package | Repo, npm publish workflow |

---

## 🚀 Getting Started

### Local Development

```bash
# Install dependencies
make install

# Start Backstage locally
make dev

# Open http://localhost:7007
```

### Deploy to EKS (requires AWS access)

```bash
# Deploy to development environment
make deploy ENV=dev

# Promote to staging (requires approval gate)
make deploy ENV=staging

# Promote to production (double approval required)
make deploy ENV=prod
```

### Create a New Service via the Portal

1. Navigate to **Scaffolder → Create New Component**
2. Select template (e.g., "Node.js Microservice")
3. Fill in form: service name, description, tech stack
4. Review and submit
5. The portal creates a new GitHub repo with all scaffolding outputs
6. CI/CD pipelines activate automatically

---

## 📁 Directory Layout

```
developer-portal/
├── README.md                      # This file
├── Makefile                       # Build, deploy, test targets
├── Dockerfile                     # Backstage container image
├── docker-compose.dev.yaml        # Local dev with Postgres + Keycloak
├── .gitignore
│
├── package.json                   # Root workspace config
├── app/                           # Backstage application
│   ├── package.json               # App dependencies
│   ├── tsconfig.json              # TypeScript config
│   ├── app-config.yaml            # Backstage configuration
│   ├── app-config.production.yaml # Production overrides
│   ├── app.ts                     # Application bootstrap
│   ├── catalog-info.yaml          # Portal itself (self-registration)
│   │
│   ├── plugins/                   # Custom plugins
│   │   ├── scaffold-plugin/       # Enhanced scaffolder actions
│   │   └── template-provider/     # Template registry & preview
│   │
│   └── packages/                  # Workspace packages
│       ├── app/                   # Frontend React app
│       └── backend/               # Express API server
│
├── software-templates/            # Software Template definitions
│   ├── nodejs-microservice/       # Node.js template
│   │   └── scaffold.yml           # Template spec + actions
│   ├── react-frontend/            # React SPA template
│   │   └── scaffold.yml
│   ├── go-service/                # Go gRPC service template
│   │   └── scaffold.yml
│   ├── terraform-module/          # IaC module template
│   │   └── scaffold.yml
│   └── shared-library/            # TypeScript library template
│       └── scaffold.yml
│
├── catalog-info/                  # Pre-built catalog entries
│   ├── platform-backstage.yaml    # Portal registration
│   └── example-services/          # Example catalog items
│       ├── order-service-api.yaml
│       └── user-auth-service.yaml
│
├── k8s-manifests/                 # Kubernetes deployment manifests
│   ├── base/                      # Base Kustomize resources
│   │   ├── namespace.yaml
│   │   ├── backstage-deployment.yaml
│   │   ├── backstage-service.yaml
│   │   ├── ingress.yaml
│   │   ├── hpa.yaml
│   │   └── kustomization.yaml
│   │
│   └── overlays/                  # Environment overlays
│       ├── dev/kustomization.yaml
│       ├── staging/kustomization.yaml
│       └── prod/kustomization.yaml
│
├── environments/                  # Terraform environment modules
│   ├── dev/                       # Dev environment config
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── staging/                   # Staging environment config
│   │   ├── main.tf
│   │   └── variables.tf
│   └── prod/                      # Production environment config
│       ├── main.tf
│       └── variables.tf
│
├── providers/                     # Shared infrastructure module
│   ├── main.tf                    # EKS, RDS, ECR, etc.
│   ├── variables.tf
│   └── versions.tf
│
├── scripts/                       # Utility scripts
│   ├── setup.sh                   # Local dev setup
│   └── destroy.sh                 # Tear down all environments
│
└── .github/workflows/             # GitHub Actions pipelines
    ├── ci.yml                     # Build, validate, scan
    ├── cd-dev.yml                 # Deploy to dev (auto)
    ├── cd-staging.yml             # Deploy to staging (approval)
    ├── cd-prod.yml                # Deploy to prod (double approval)
    └── drift-detection.yml        # Scheduled drift checks
```

---

## 🔄 CI/CD Pipeline

The portal has its own robust CI/CD pipeline plus orchestrates delivery of scaffolded services.

### Portal CI/CD Flow

```
Push to main
  ├── Lint (Backstage CLI) ─────┐
  ├── Type Check (tsc)          │
  ├── Build App                 ├─→ All pass → Deploy to dev
  ├── Validate Templates        │
  ├── Kustomize Validation      │
  ├── Scaffolder Action Tests   │
  ├── Terraform Validate        │
  └── Full Pipeline Status ─────┘
```

### Scaffolded Service CI/CD Flow

```
Developer scaffolds service
  → New GitHub repo created (via webhook)
    ├── Lint & Test (unit + integration)
    ├── Build & Push to ECR
    ├── Trivy vulnerability scan
    ├── TruffleHog secret scan
    ├── Deploy to dev namespace via ArgoCD
    └── Manual approval gates for staging → prod
```

---

## ⛩️ ArgoCD Integration

The portal is deployed through **ArgoCD Applications** that manage the entire lifecycle:

### Backstage Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backstage-idp-dev
spec:
  source:
    repoURL: 'https://github.com/tomwire/developer-portal.git'
    targetRevision: main
    path: k8s-manifests/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: idp-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true    # Auto-corrects drift in dev/staging
    syncOptions:
      - CreateNamespace=true
```

### Scaffolded Service Applications (Auto-Created)

When a service is scaffolded, the scaffolder creates an ArgoCD Application manifest:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: order-service-api-dev
spec:
  source:
    repoURL: 'https://github.com/tomwire/order-service-api.git'
    targetRevision: main
    path: k8s-manifests/overlays/dev
  destination:
    namespace: idp-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 🏗️ Infrastructure as Code

The platform runs on AWS EKS, provisioned entirely through Terraform:

### Shared Provider Module

| Resource | Purpose |
|----------|---------|
| **EKS Cluster** | Kubernetes control plane + managed node groups |
| **IAM Roles** | OIDC federated roles for GitHub Actions |
| **ECR Repositories** | Container image registry (per-env) |
| **RDS PostgreSQL** | Backstage catalog database |
| **Secrets Manager** | Application secrets with rotation |
| **VPC / Subnets** | Isolated networking with private/public tiers |

### Environment Separation

Each environment (dev/staging/prod) gets:
- Separate EKS cluster (dev shares, staging/prod isolated)
- Dedicated namespace in ArgoCD
- Independent RDS instance (shared DB in dev)
- ECR repository prefix (`dev/`, `staging/`, `prod/`)

---

## 🔍 Drift Detection

A scheduled GitHub Action runs **every 6 hours** to detect configuration drift between Git-defined state and live cluster:

### What It Checks

1. **Replica count drift** — did someone manually scale?
2. **Image tag drift** — is the running image different from Git?
3. **Resource config drift** — are limits/requests unchanged?
4. **Secret drift** — have secrets been modified outside GitOps?

### Drift Response

| Environment | Action |
|-------------|--------|
| **Dev** | Auto-reports to Slack, creates GitHub issue for review |
| **Staging** | Alerts team, triggers selfHeal via ArgoCD annotation |
| **Prod** | Blocks sync, alerts SRE on-call, creates P1 incident |

---

## 📖 Templates Reference

### Node.js Microservice Template

```yaml
# software-templates/nodejs-microservice/scaffold.yml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: nodejs-microservice
  title: Node.js Microservice
  description: Create a new production-ready Node.js microservice

spec:
  owner: platform-team
  type: service

  parameters:
    - title: Provide service details
      required:
        - serviceName
        - description
      properties:
        serviceName:
          title: Service Name
          type: string
          description: Unique name for your service
        description:
          title: Description
          type: string
        owner:
          title: Owner
          type: string
          description: GitHub team or user

  steps:
    - id: fetch-base
      name: Fetch Base Template
      action: fetch:template
      input:
        url: ./templates/nodejs-microservice
        values:
          serviceName: ${{ parameters.serviceName }}
          description: ${{ parameters.description }}

    - id: publish
      name: Publish to GitHub
      action: publish:github
      input:
        allowedHosts: ['github.com']
        repoUrl: github.com?owner=tomwire&repo=${{ parameters.serviceName }}

    - id: register
      name: Register in Catalog
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
        catalogInfoPath: 'catalog-info.yaml'

  output:
    links:
      - title: Repository
        url: ${{ steps.publish.output.remoteUrl }}
      - title: Catalog Entity
        to: ${{ steps.register.output.catalogRef }}
```

### Scaffolding Outputs (Sample)

Each scaffolded Node.js service produces **~30 files** across multiple repos:

```
order-service-api/
├── src/
│   ├── app.ts                    # Express/Fastify entry point
│   ├── routes/                   # API route handlers
│   └── middleware/               # Auth, logging, error handling
├── test/
│   ├── unit/                     # Jest test suites
│   └── integration/              # API contract tests
├── k8s-manifests/
│   ├── base/
│   │   ├── deployment.yaml       # 3 replicas, CPU/Memory limits
│   │   ├── service.yaml          # ClusterIP + Ingress config
│   │   └── network-policy.yaml   # egress-only (API access)
│   └── overlays/                 # Dev/Staging/Prod Kustomize overlays
├── terraform/
│   ├── main.tf                   # EKS namespace, IAM role, secrets
│   └── variables.tf
├── .github/workflows/
│   ├── ci.yml                    # Build, test, scan
│   └── cd-dev.yml                # Auto-deploy to dev
├── Dockerfile                    # Multi-stage, distroless final
├── Makefile                      # Standard targets (build/test/deploy)
├── catalog-info.yaml             # Backstage entity definition
└── README.md                     # Generated docs
```

---

## 🤝 Contributing

This project follows the same standards as our other infrastructure repos:

```bash
# Set up local development
make setup

# Run all checks
make ci

# Deploy to an environment
make deploy ENV=dev    # Auto-sync
make deploy ENV=staging  # Requires approval gate
make deploy ENV=prod     # Double approval required
```

See the [Backstage Documentation](https://backstage.io/docs) for template and plugin development guides.

---

## 📊 Portfolio Context

This project complements the other three repos in my DevOps portfolio:

| Repo | Focus | Technologies |
|------|-------|-------------|
| **enterprise-terraform-aws** | Infrastructure as Code | Terraform, AWS, modular state management |
| **eks-observability** | Platform Observability | Prometheus, Grafana, OpenTelemetry, EKS |
| **multi-gitops-pipeline** | GitOps Workflows | ArgoCD, Kustomize, multi-stage promotion |
| **developer-portal** ⬅️ You are here | Developer Experience | Backstage, Software Templates, self-service CI/CD |

---

_Built with ❤️ by Thomas Wire — Platform Engineering Portfolio_
