# =============================================================================
# Staging Environment — Main Terraform Configuration
# =============================================================================

terraform {
  backend "s3" {
    bucket = "developer-portal-terraform-state"
    key    = "staging/terraform.tfstate"
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
  cluster_name = "staging"
  namespace    = "idp-staging"
}

module "infrastructure" {
  source = "../../providers"

  project_name     = "developer-portal"
  cluster_name     = local.cluster_name
  environment      = "staging"
  vpc_id           = var.vpc_id
  subnet_ids       = var.subnet_ids
  namespace        = local.namespace
  instance_type    = "t3.medium"
  desired_nodes    = 2
  max_nodes        = 5
  min_nodes        = 1

  db_username = "backstage"
  db_password = "changeme-staging-only"
}

output "cluster_name" {
  value = module.infrastructure.cluster_name
}

output "ecr_repository_url" {
  value = "${module.infrastructure.ecr_repository_url}/backstage"
}
