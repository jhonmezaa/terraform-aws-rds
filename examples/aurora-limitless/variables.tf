# =============================================================================
# General Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "account_name" {
  description = "Account name for resource naming"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "limitless-demo"
}

# =============================================================================
# Network Variables
# =============================================================================

variable "vpc_id" {
  description = "VPC ID where Aurora cluster will be deployed"
  type        = string
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for Aurora cluster (must span at least 2 AZs)"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for Aurora cluster"
  type        = list(string)
}

# =============================================================================
# Aurora Limitless Configuration
# =============================================================================

variable "db_username" {
  description = "Master username for Aurora cluster"
  type        = string
  default     = "limitless_admin"
}

variable "engine_version" {
  description = "PostgreSQL engine version (must be 15.5 or higher for Limitless)"
  type        = string
  default     = "15.5"
}

variable "instance_class" {
  description = "Instance class for Aurora instances"
  type        = string
  default     = "db.r6g.xlarge"
}

variable "instance_count" {
  description = "Number of Aurora instances"
  type        = number
  default     = 2
}

variable "max_acu" {
  description = "Maximum ACU for shard group (768 to 3145728)"
  type        = number
  default     = 1536
}

variable "min_acu" {
  description = "Minimum ACU for shard group"
  type        = number
  default     = 768
}

variable "compute_redundancy" {
  description = "Compute redundancy for shard group (0, 1, or 2)"
  type        = number
  default     = 2
}

# =============================================================================
# Tags
# =============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Example     = "AuroraLimitless"
  }
}
