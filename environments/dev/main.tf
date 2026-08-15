# =============================================================================
# Dev Environment — Main Terraform Configuration
# =============================================================================

terraform {
  backend "s3" {
    bucket = "developer-portal-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  cluster_name = "dev"
  namespace    = "idp-dev"
}

module "infrastructure" {
  source = "../../providers"

  project_name     = "developer-portal"
  cluster_name     = local.cluster_name
  environment      = "dev"
  vpc_id           = var.vpc_id
  subnet_ids       = var.subnet_ids
  namespace        = local.namespace
  instance_type    = "t3.small"
  desired_nodes    = 2
  max_nodes        = 5
  min_nodes        = 1

  # No RDS in dev — use SQLite (Backstage default)
  db_username = null
  db_password = null
}

output "cluster_name" {
  value = module.infrastructure.cluster_name
}

output "ecr_repository_url" {
  value = "${module.infrastructure.ecr_repository_url}/backstage"
}
