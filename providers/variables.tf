# =============================================================================
# Developer Portal — Provider Module Variables
# =============================================================================

variable "project_name" {
  description = "Project name (used as prefix for resources)"
  type        = string
  default     = "developer-portal"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster and node group"
  type        = list(string)
}

variable "namespace" {
  description = "Kubernetes namespace for this environment"
  type        = string
  default     = "idp-dev"
}

variable "instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "desired_nodes" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Maximum number of nodes for auto-scaling"
  type        = number
  default     = 5
}

variable "min_nodes" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "db_username" {
  description = "Database master username (prod only)"
  type        = string
  sensitive   = true
  default     = "backstage"
}

variable "db_password" {
  description = "Database master password (prod only, use secrets manager in prod)"
  type        = string
  sensitive   = true
  default     = "changeme-dev-only"
}
