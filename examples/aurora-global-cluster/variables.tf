# =============================================================================
# Aurora Global Cluster Example - Variables
# =============================================================================

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
  default     = "global-demo"
}

# =============================================================================
# Region Configuration
# =============================================================================

variable "primary_region" {
  description = "Primary region for the global cluster (writer region)"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary region for the global cluster (read replica region)"
  type        = string
  default     = "us-west-2"
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
  default     = "globaldb"
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
# Primary Region Network Configuration
# =============================================================================

variable "primary_vpc_security_group_ids" {
  description = "List of VPC security group IDs for primary cluster"
  type        = list(string)
}

variable "primary_database_subnet_ids" {
  description = "List of subnet IDs for primary cluster database subnet group"
  type        = list(string)
}

# =============================================================================
# Secondary Region Network Configuration
# =============================================================================

variable "secondary_vpc_security_group_ids" {
  description = "List of VPC security group IDs for secondary cluster"
  type        = list(string)
}

variable "secondary_database_subnet_ids" {
  description = "List of subnet IDs for secondary cluster database subnet group"
  type        = list(string)
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
    Example     = "AuroraGlobalCluster"
    Purpose     = "Multi-Region Disaster Recovery"
  }
}
