# =============================================================================
# Aurora Serverless v2 Example - Variables
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
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "dev_db"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for the Aurora cluster"
  type        = list(string)
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for Aurora subnet group (at least 2 in different AZs)"
  type        = list(string)
}

variable "min_capacity" {
  description = "Minimum ACU capacity for Serverless v2"
  type        = number
  default     = 0.5
}

variable "max_capacity" {
  description = "Maximum ACU capacity for Serverless v2"
  type        = number
  default     = 2.0
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
