# =============================================================================
# Standard RDS PostgreSQL Example - Variables
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
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.4"
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
  description = "Instance class for the primary RDS instance"
  type        = string
  default     = "db.r6g.large"
}

variable "replica_instance_class" {
  description = "Instance class for the read replica"
  type        = string
  default     = "db.r6g.large"
}

variable "replica_availability_zone" {
  description = "Availability zone for the read replica"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for the RDS instances"
  type        = list(string)
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for the DB subnet group (at least 2 in different AZs)"
  type        = list(string)
}
