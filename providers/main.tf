# =============================================================================
# Developer Portal — Provider Module (Shared Infrastructure)
# =============================================================================
# Defines shared EKS cluster, RDS, ECR, and IAM resources used across all
# environments. Each environment gets its own namespace within the cluster.
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
# EKS Cluster (shared across environments in dev/staging, isolated in prod)
# ---------------------------------------------------------------------------
resource "aws_eks_cluster" "main" {
  name     = "${var.cluster_name}-idp"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.eks_cluster.id]
  }

  tags = {
    Project     = "developer-portal"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# IAM Role for EKS
# ---------------------------------------------------------------------------
resource "aws_iam_role" "eks_role" {
  name = "${var.cluster_name}-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Security Group for EKS
# ---------------------------------------------------------------------------
resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-sg"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------
# Node Group for EKS
# ---------------------------------------------------------------------------
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.subnet_ids
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = var.desired_nodes
    max_size     = var.max_nodes
    min_size     = var.min_nodes
  }

  tags = {
    Project     = "developer-portal"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# IAM Role for EKS Nodes
# ---------------------------------------------------------------------------
resource "aws_iam_role" "node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# ECR Repository for Backstage images
# ---------------------------------------------------------------------------
resource "aws_ecr_repository" "backstage" {
  name                 = "${var.environment}/${var.project_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = "developer-portal"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# RDS PostgreSQL for Backstage catalog database (prod only)
# ---------------------------------------------------------------------------
resource "aws_db_instance" "backstage" {
  count        = var.environment == "prod" ? 1 : 0
  identifier   = "${var.cluster_name}-backstage-db"
  engine       = "postgres"
  engine_version = "16"
  instance_class = "db.t3.medium"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  db_name  = "backstage"
  username = var.db_username
  password = var.db_password

  skip_final_snapshot       = true
  deletion_protection       = var.environment == "prod" ? true : false
  backup_retention_period   = 30
  multi_az                  = true
  publicly_accessible       = false
  vpc_security_group_ids    = [aws_security_group.db.id]
  db_subnet_group_name      = aws_db_subnet_group.main.name

  tags = {
    Project     = "developer-portal"
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "main" {
  count      = var.environment == "prod" ? 1 : 0
  name       = "${var.cluster_name}-db-subnet"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "db" {
  count      = var.environment == "prod" ? 1 : 0
  name       = "${var.cluster_name}-db-sg"
  vpc_id     = var.vpc_id
  description = "Allow access from EKS nodes"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------
# GitHub OIDC Provider for Actions (used by all scaffolded services)
# ---------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1234567890abcdef1234567890abcdef12345678"]

  tags = {
    Project     = "developer-portal"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Output values for environment configuration
# ---------------------------------------------------------------------------
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "ecr_repository_url" {
  description = "ECR repository for Backstage images"
  value       = aws_ecr_repository.backstage.repository_url
}

output "namespace" {
  description = "Kubernetes namespace for the environment"
  value       = var.namespace
}
