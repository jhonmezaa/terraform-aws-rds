# =============================================================================
# Aurora MySQL Advanced Example
# =============================================================================
# This example demonstrates advanced Aurora MySQL features:
# - Backtrack (rewind database to previous point in time)
# - Binary log replication configuration
# - MySQL-specific CloudWatch logs (audit, error, general, slowquery)
# - Advanced parameter groups for MySQL optimization
# - Performance Insights with extended retention
# - Multi-AZ high availability
# =============================================================================

module "aurora_mysql" {
  source = "../../rds"

  account_name = var.account_name
  project_name = var.project_name

  clusters = {
    mysql = {
      # =======================================================================
      # ENGINE CONFIGURATION
      # =======================================================================

      engine         = "aurora-mysql"
      engine_version = var.engine_version
      engine_mode    = "provisioned"

      # Database
      database_name = var.database_name

      # =======================================================================
      # CREDENTIALS (AWS Secrets Manager)
      # =======================================================================

      master_username             = var.db_username
      manage_master_user_password = true

      # =======================================================================
      # NETWORK CONFIGURATION
      # =======================================================================

      vpc_security_group_ids = var.vpc_security_group_ids
      subnet_ids             = var.database_subnet_ids
      create_subnet_group    = true
      publicly_accessible    = false

      # =======================================================================
      # BACKUP CONFIGURATION
      # =======================================================================

      backup_retention_period      = var.backup_retention_period
      preferred_backup_window      = var.preferred_backup_window
      preferred_maintenance_window = var.preferred_maintenance_window
      skip_final_snapshot          = !var.deletion_protection
      final_snapshot_identifier    = "${var.account_name}-${var.project_name}-final-snapshot"
      copy_tags_to_snapshot        = true

      # =======================================================================
      # BACKTRACK (MySQL-specific feature)
      # =======================================================================
      # Allows rewinding the database to any point in time within the window
      # without restoring from a backup

      backtrack_window = var.backtrack_window # 24 hours (86400 seconds)

      # =======================================================================
      # ENCRYPTION
      # =======================================================================

      storage_encrypted = true
      kms_key_id        = null # Use default AWS managed key

      # =======================================================================
      # DELETION PROTECTION
      # =======================================================================

      deletion_protection = var.deletion_protection

      # =======================================================================
      # PERFORMANCE INSIGHTS
      # =======================================================================

      performance_insights_enabled          = true
      performance_insights_retention_period = var.performance_insights_retention_period

      # =======================================================================
      # CLOUDWATCH LOGS (MySQL-specific)
      # =======================================================================
      # Enable all MySQL log types for comprehensive monitoring

      enabled_cloudwatch_logs_exports = [
        "audit",    # Audit logs for security and compliance
        "error",    # Error logs for troubleshooting
        "general",  # General query logs (can be verbose)
        "slowquery" # Slow query logs for performance tuning
      ]

      # =======================================================================
      # CLUSTER PARAMETERS (MySQL-specific)
      # =======================================================================

      cluster_parameter_group = {
        family      = "aurora-mysql8.0"
        description = "Custom cluster parameters for Aurora MySQL"
        parameters = [
          # Binary Log Configuration
          {
            name         = "binlog_format"
            value        = var.binlog_format
            apply_method = "pending-reboot"
          },
          # Character Set
          {
            name         = "character_set_server"
            value        = "utf8mb4"
            apply_method = "immediate"
          },
          # Collation
          {
            name         = "collation_server"
            value        = "utf8mb4_unicode_ci"
            apply_method = "immediate"
          },
          # Time Zone
          {
            name         = "time_zone"
            value        = "UTC"
            apply_method = "immediate"
          },
          # Max Connections
          {
            name         = "max_connections"
            value        = "1000"
            apply_method = "immediate"
          },
          # Enable Slow Query Log
          {
            name         = "slow_query_log"
            value        = "1"
            apply_method = "immediate"
          },
          # Slow Query Threshold (seconds)
          {
            name         = "long_query_time"
            value        = "2"
            apply_method = "immediate"
          },
          # Log queries not using indexes
          {
            name         = "log_queries_not_using_indexes"
            value        = "1"
            apply_method = "immediate"
          },
          # Enable General Log (can be verbose - use with caution)
          {
            name         = "general_log"
            value        = "0" # Disabled by default
            apply_method = "immediate"
          },
          # Server Audit Logging (for audit log export)
          {
            name         = "server_audit_logging"
            value        = "1"
            apply_method = "immediate"
          },
          # Audit log events to capture
          {
            name         = "server_audit_events"
            value        = "CONNECT,QUERY,TABLE"
            apply_method = "immediate"
          }
        ]
      }

      # =======================================================================
      # DB INSTANCE PARAMETERS (MySQL-specific)
      # =======================================================================

      db_parameter_group = {
        family      = "aurora-mysql8.0"
        description = "Custom instance parameters for Aurora MySQL"
        parameters = [
          # InnoDB Buffer Pool Size (% of instance memory)
          # For db.r6g.large (16 GB RAM), default is ~75%
          {
            name         = "innodb_buffer_pool_size"
            value        = "{DBInstanceClassMemory*3/4}"
            apply_method = "pending-reboot"
          },
          # InnoDB Log File Size
          {
            name         = "innodb_log_file_size"
            value        = "536870912" # 512 MB
            apply_method = "pending-reboot"
          },
          # InnoDB Flush Method
          {
            name         = "innodb_flush_method"
            value        = "O_DIRECT"
            apply_method = "pending-reboot"
          },
          # Max Allowed Packet
          {
            name         = "max_allowed_packet"
            value        = "67108864" # 64 MB
            apply_method = "immediate"
          }
        ]
      }

      # =======================================================================
      # INSTANCES (Writer + Readers)
      # =======================================================================

      instances = {
        writer = {
          instance_class      = var.instance_class
          publicly_accessible = false
          promotion_tier      = 0 # Writer instance

          # Writer-specific monitoring
          monitoring_interval = 60   # Enhanced monitoring every 60 seconds
          monitoring_role_arn = null # Auto-created by module
        }

        reader1 = {
          instance_class      = var.instance_class
          publicly_accessible = false
          promotion_tier      = 1 # First reader

          # Reader-specific configuration
          monitoring_interval = 60
          monitoring_role_arn = null
        }

        reader2 = {
          instance_class      = var.instance_class
          publicly_accessible = false
          promotion_tier      = 2 # Second reader

          monitoring_interval = 60
          monitoring_role_arn = null
        }
      }

      # =======================================================================
      # TAGS
      # =======================================================================

      tags = merge(var.tags, {
        Engine       = "aurora-mysql"
        Backtrack    = var.backtrack_window > 0 ? "Enabled" : "Disabled"
        BinlogFormat = var.binlog_format
      })
    }
  }

  tags_common = var.tags
}
