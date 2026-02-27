# =============================================================================
# Standard RDS MySQL Example - Variables
# =============================================================================

variable "account_name" {
  description = "Account name for resource naming"
  type        = string
  default     = "mycompany"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "myapp"
}

variable "engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0.36"
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "app_db"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.r6g.large"
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for the RDS instance"
  type        = list(string)
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for the DB subnet group (at least 2 in different AZs)"
  type        = list(string)
}
