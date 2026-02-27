# =============================================================================
# Standard RDS PostgreSQL Example
# - Primary instance with Multi-AZ
# - Storage autoscaling (gp3)
# - Secrets Manager password management
# - Performance Insights + Enhanced Monitoring
# - Custom parameter group
# - Read replica via self-referencing
# =============================================================================

module "rds_postgresql" {
  source = "../../rds"

  account_name = var.account_name
  project_name = var.project_name

  tags_common = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }

  instances = {
    # Primary PostgreSQL instance
    primary = {
      engine         = "postgres"
      engine_version = var.engine_version
      instance_class = var.instance_class

      # Storage (gp3 with autoscaling)
      allocated_storage     = 100
      max_allocated_storage = 500
      storage_type          = "gp3"
      iops                  = 3000
      storage_throughput    = 125

      # Database
      database_name = var.database_name

      # Credentials (Secrets Manager)
      master_username             = var.db_username
      manage_master_user_password = true

      # Network
      vpc_security_group_ids = var.vpc_security_group_ids
      subnet_ids             = var.database_subnet_ids
      create_subnet_group    = true
      multi_az               = true

      # Backup
      backup_retention_period = 30
      backup_window           = "03:00-04:00"
      maintenance_window      = "sun:04:00-sun:05:00"
      skip_final_snapshot     = false
      copy_tags_to_snapshot   = true

      # Security
      storage_encrypted   = true
      deletion_protection = true

      # Monitoring
      monitoring_interval                   = 60
      create_monitoring_role                = true
      performance_insights_enabled          = true
      performance_insights_retention_period = 7

      # CloudWatch Logs
      enabled_cloudwatch_logs_exports        = ["postgresql", "upgrade"]
      cloudwatch_log_group_retention_in_days = 30

      # Parameter Group
      parameter_group = {
        family      = "postgres16"
        description = "Custom PostgreSQL 16 parameter group"
        parameters = [
          {
            name         = "log_min_duration_statement"
            value        = "1000"
            apply_method = "immediate"
          },
          {
            name         = "shared_preload_libraries"
            value        = "pg_stat_statements"
            apply_method = "pending-reboot"
          },
          {
            name         = "log_connections"
            value        = "1"
            apply_method = "immediate"
          },
          {
            name         = "log_disconnections"
            value        = "1"
            apply_method = "immediate"
          }
        ]
      }

      # Version Upgrades
      auto_minor_version_upgrade  = true
      allow_major_version_upgrade = false
      apply_immediately           = false

      tags = {
        Role   = "primary"
        Engine = "postgresql"
      }
    }

    # Read Replica (self-referencing)
    replica = {
      engine         = "postgres"
      engine_version = var.engine_version
      instance_class = var.replica_instance_class

      # Storage (inherited from source, but can override type)
      storage_type = "gp3"

      # Read Replica - references primary instance in this module
      replicate_source_db = "self:primary"

      # Network
      vpc_security_group_ids = var.vpc_security_group_ids
      availability_zone      = var.replica_availability_zone

      # Monitoring
      monitoring_interval                   = 60
      create_monitoring_role                = true
      performance_insights_enabled          = true
      performance_insights_retention_period = 7

      # CloudWatch Logs
      enabled_cloudwatch_logs_exports        = ["postgresql"]
      cloudwatch_log_group_retention_in_days = 30

      # Deletion
      deletion_protection   = false
      skip_final_snapshot   = true
      copy_tags_to_snapshot = true

      tags = {
        Role   = "replica"
        Engine = "postgresql"
      }
    }
  }
}
