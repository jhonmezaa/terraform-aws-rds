# =============================================================================
# Aurora MySQL Cluster Example - Variables
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
  description = "Aurora MySQL engine version"
  type        = string
  default     = "8.0.mysql_aurora.3.04.0"
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "prod_db"
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

variable "instance_class" {
  description = "Instance class for Aurora instances"
  type        = string
  default     = "db.r6g.large"
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of Aurora replicas for autoscaling"
  type        = number
  default     = 2
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of Aurora replicas for autoscaling"
  type        = number
  default     = 6
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization for autoscaling"
  type        = number
  default     = 70
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
