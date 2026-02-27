# =============================================================================
# Standard RDS MySQL Example
# - Multi-AZ deployment
# - Option group with MariaDB Audit Plugin
# - CloudWatch logs export
# - Secrets Manager password management
# - Custom parameter group
# =============================================================================

module "rds_mysql" {
  source = "../../rds"

  account_name = var.account_name
  project_name = var.project_name

  tags_common = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }

  instances = {
    # Production MySQL instance
    main = {
      engine         = "mysql"
      engine_version = var.engine_version
      instance_class = var.instance_class

      # Storage
      allocated_storage     = 50
      max_allocated_storage = 200
      storage_type          = "gp3"

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
      backup_retention_period = 14
      backup_window           = "02:00-03:00"
      maintenance_window      = "sun:03:00-sun:04:00"
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
      enabled_cloudwatch_logs_exports        = ["audit", "error", "general", "slowquery"]
      cloudwatch_log_group_retention_in_days = 30

      # Parameter Group
      parameter_group = {
        family      = "mysql8.0"
        description = "Custom MySQL 8.0 parameter group"
        parameters = [
          {
            name         = "slow_query_log"
            value        = "1"
            apply_method = "immediate"
          },
          {
            name         = "long_query_time"
            value        = "2"
            apply_method = "immediate"
          },
          {
            name         = "log_output"
            value        = "FILE"
            apply_method = "immediate"
          },
          {
            name         = "general_log"
            value        = "0"
            apply_method = "immediate"
          }
        ]
      }

      # Option Group
      option_group = {
        name                 = null
        engine_name          = null
        major_engine_version = "8.0"
        description          = "MySQL 8.0 option group with audit plugin"
        options = [
          {
            option_name                    = "MARIADB_AUDIT_PLUGIN"
            port                           = null
            version                        = null
            db_security_group_memberships  = []
            vpc_security_group_memberships = []
            option_settings = [
              {
                name  = "SERVER_AUDIT_EVENTS"
                value = "CONNECT,QUERY_DCL,QUERY_DDL"
              },
              {
                name  = "SERVER_AUDIT_FILE_ROTATIONS"
                value = "20"
              }
            ]
          }
        ]
      }

      # Blue/Green Deployment
      blue_green_update = {
        enabled = true
      }

      # Version Upgrades
      auto_minor_version_upgrade  = true
      allow_major_version_upgrade = false
      apply_immediately           = false

      tags = {
        Role   = "primary"
        Engine = "mysql"
      }
    }
  }
}
