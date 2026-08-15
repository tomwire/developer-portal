# =============================================================================
# Production Environment — Main Terraform Configuration
# =============================================================================

terraform {
  backend "s3" {
    bucket = "developer-portal-terraform-state"
    key    = "prod/terraform.tfstate"
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
  cluster_name = "prod"
  namespace    = "idp-prod"
}

module "infrastructure" {
  source = "../../providers"

  project_name     = "developer-portal"
  cluster_name     = local.cluster_name
  environment      = "prod"
  vpc_id           = var.vpc_id
  subnet_ids       = var.subnet_ids
  namespace        = local.namespace
  instance_type    = "t3.large"
  desired_nodes    = 3
  max_nodes        = 10
  min_nodes        = 3

  # Production RDS with encryption, backups, and multi-AZ
  db_username = var.db_username
  db_password = var.db_password
}

output "cluster_name" {
  value = module.infrastructure.cluster_name
}

output "ecr_repository_url" {
  value = "${module.infrastructure.ecr_repository_url}/backstage"
}
