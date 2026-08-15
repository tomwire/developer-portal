/*
 * Copyright 2024 The Developer Portal Platform Authors
 * Licensed under the Apache License, Version 2.0
 */

import { createBackend } from '@backstage/backend-defaults';

const backend = createBackend();

// =============================================================
// Core services
// =============================================================
backend.add(import('@backstage/plugin-catalog-backend'));
backend.add(import('@backstage/plugin-auth-backend'));
backend.add(import('@backstage/plugin-scaffolder-backend'));
backend.add(import('@backstage/plugin-kubernetes-backend'));
backend.add(import('@backstage/plugin-search-backend'));

// =============================================================
// Auth providers (enable in production)
// =============================================================
// backend.add(import('@backstage/plugin-auth-backend-module-github-provider'));

// =============================================================
// Catalog import sources
// =============================================================
backend.add(
  import('@backstage/plugin-catalog-backend-module-scaffolder-entity-model'),
);

// =============================================================
// Search backends
// =============================================================
backend.add(import('@backstage/plugin-search-backend-module-catalog'));

// =============================================================
// Custom scaffolder actions (software templates)
// =============================================================
// These actions are registered from local plugins that extend
// the default scaffolder actions with platform-specific logic:
// - GitHub repo creation with pre-configured CI/CD workflows
// - Kustomize overlay generation for target environment
// - Terraform module scaffolding
// - ArgoCD Application manifest generation

// =============================================================
// Start server
// =============================================================
backend.start();
