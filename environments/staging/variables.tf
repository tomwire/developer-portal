# =============================================================================
# Staging Environment — Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region for the staging environment"
  type        = string
  default     = "us-east-2"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)
  default     = []
}
