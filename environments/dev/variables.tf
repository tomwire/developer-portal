# =============================================================================
# Dev Environment — Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region for the dev environment"
  type        = string
  default     = "us-east-2"
}

variable "vpc_id" {
  description = "VPC ID (provide in production, use default in dev)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)
  default     = []
}
