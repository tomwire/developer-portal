# =============================================================================
# Developer Portal — Dockerfile (Backstage App)
# =============================================================================
# Multi-stage build: install deps → build app → distroless runtime
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1: Install dependencies
# ---------------------------------------------------------------------------
FROM public.ecr.aws/docker/library/node:20-bookworm-slim AS deps

WORKDIR /app

# Copy monorepo workspace files
COPY package.json package-lock.json* ./
COPY app/package.json ./app/

RUN npm ci --ignore-scripts || npm install

# ---------------------------------------------------------------------------
# Stage 2: Build the Backstage application
# ---------------------------------------------------------------------------
FROM deps AS build

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/app/node_modules ./app/node_modules

# Copy all source files (including templates and k8s manifests)
COPY . .

RUN npx backstage-cli repo build --all

# ---------------------------------------------------------------------------
# Stage 3: Runtime — minimal Distroless image
# ---------------------------------------------------------------------------
FROM public.ecr.aws/docker/library/node:20-bookworm-slim AS runtime

WORKDIR /app

# Create non-root user (same UID as in Backstage default)
RUN groupadd -g 1001 backstage && \
    useradd -u 1001 -g backstage -m backstage

# Copy built artifacts from build stage
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/app/package.json ./app/package.json
COPY --from=build /app/app/dist ./app/dist
COPY --from=build /app/packages ./packages
COPY --from=build /app/plugins ./plugins
COPY --from=build /app/node_modules ./node_modules

# Copy backend (Express server)
COPY --from=build /app/backend ./backend
RUN ls -la backend 2>/dev/null || true

USER 1001

EXPOSE 7007

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s \
    CMD node -e "require('http').get('http://localhost:7007/healthz', (r) => { process.exit(r.statusCode === 200 ? 0 : 1) })"

CMD ["node", "app/dist/index.js"]
