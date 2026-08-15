# =============================================================================
# Provider Module — Required Providers & Versions
# =============================================================================

terraform {
  required_version: ">= 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# ---------------------------------------------------------------------------
# Region overrides per environment
# ---------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "developer-portal"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
