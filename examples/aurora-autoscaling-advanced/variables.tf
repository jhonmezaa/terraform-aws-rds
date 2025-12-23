# =============================================================================
# Aurora Advanced Autoscaling Example - Variables
# =============================================================================

# =============================================================================
# Region Configuration
# =============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# =============================================================================
# Naming Variables
# =============================================================================

variable "account_name" {
  description = "Account name for resource naming (e.g., 'dev', 'staging', 'prod')"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "autoscaling-demo"
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "vpc_id" {
  description = "VPC ID where the Aurora cluster will be deployed"
  type        = string
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for database subnet group (at least 2 in different AZs)"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs to attach to the cluster"
  type        = list(string)
}

# =============================================================================
# Database Configuration
# =============================================================================

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "autoscaling_db"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "instance_class" {
  description = "Instance class for Aurora instances"
  type        = string
  default     = "db.r6g.large"
}

# =============================================================================
# Autoscaling Configuration
# =============================================================================

variable "min_capacity" {
  description = "Minimum number of Aurora read replicas"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of Aurora read replicas"
  type        = number
  default     = 5
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for autoscaling"
  type        = number
  default     = 70
}

variable "connections_target_value" {
  description = "Target number of database connections for autoscaling"
  type        = number
  default     = 500
}

variable "scale_in_cooldown" {
  description = "Cooldown period (seconds) after scale-in activity"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Cooldown period (seconds) after scale-out activity"
  type        = number
  default     = 60
}

# =============================================================================
# Business Hours Configuration
# =============================================================================

variable "business_hours_start" {
  description = "Cron expression for business hours start (scale up)"
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)" # 8 AM Mon-Fri UTC
}

variable "business_hours_end" {
  description = "Cron expression for business hours end (scale down)"
  type        = string
  default     = "cron(0 18 ? * MON-FRI *)" # 6 PM Mon-Fri UTC
}

variable "business_hours_min_capacity" {
  description = "Minimum capacity during business hours"
  type        = number
  default     = 3
}

variable "business_hours_max_capacity" {
  description = "Maximum capacity during business hours"
  type        = number
  default     = 10
}

variable "off_hours_min_capacity" {
  description = "Minimum capacity during off-hours"
  type        = number
  default     = 1
}

variable "off_hours_max_capacity" {
  description = "Maximum capacity during off-hours"
  type        = number
  default     = 3
}

# =============================================================================
# Tags
# =============================================================================

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Example     = "AuroraAutoscaling"
    Purpose     = "Advanced Autoscaling Demo"
  }
}
