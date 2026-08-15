# =============================================================================
# Production Environment — Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region for the production environment"
  type        = string
  default     = "us-east-2"
}

variable "vpc_id" {
  description = "VPC ID (required in production)"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster (required in production)"
  type        = list(string)
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "backstage"
}

variable "db_password" {
  description = "Database master password (use AWS Secrets Manager in production)"
  type        = string
  sensitive   = true
}
