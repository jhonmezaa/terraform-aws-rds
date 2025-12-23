# =============================================================================
# Aurora MySQL Advanced Example - Variables
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
  default     = "mysql-demo"
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
  description = "Aurora MySQL engine version"
  type        = string
  default     = "8.0.mysql_aurora.3.05.2" # Aurora MySQL 3.05.2 (compatible with MySQL 8.0)
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "mysql_advanced_db"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
}

variable "instance_class" {
  description = "Instance class for Aurora instances"
  type        = string
  default     = "db.r6g.large"
}

# =============================================================================
# Backup Configuration
# =============================================================================

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 14
}

variable "preferred_backup_window" {
  description = "Daily time range for automated backups (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Weekly time range for maintenance (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

# =============================================================================
# Backtrack Configuration (MySQL-specific)
# =============================================================================

variable "backtrack_window" {
  description = "Target backtrack window in seconds (0 to 259200 - 72 hours). Set to 0 to disable."
  type        = number
  default     = 86400 # 24 hours
}

# =============================================================================
# Binary Log Replication
# =============================================================================

variable "binlog_format" {
  description = "Binary log format (ROW, STATEMENT, MIXED)"
  type        = string
  default     = "ROW"
}

# =============================================================================
# Performance Configuration
# =============================================================================

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days (7 or 731)"
  type        = number
  default     = 7
}

# =============================================================================
# Deletion Protection
# =============================================================================

variable "deletion_protection" {
  description = "Enable deletion protection for clusters (recommended for production)"
  type        = bool
  default     = false
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
    Example     = "AuroraMySQLAdvanced"
    Purpose     = "MySQL Advanced Features Demo"
  }
}
