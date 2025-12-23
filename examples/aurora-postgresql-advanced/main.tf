# =============================================================================
# Aurora PostgreSQL Advanced Example
# =============================================================================
# This example demonstrates advanced Aurora PostgreSQL features:
# - PostgreSQL extensions (pgvector, PostGIS, pg_stat_statements, etc.)
# - Advanced parameter tuning for PostgreSQL
# - Logical replication configuration
# - Full-text search optimization
# - JSONB and advanced data types
# - Performance Insights and monitoring
# - Multi-AZ high availability
# =============================================================================

module "aurora_postgresql" {
  source = "../../rds"

  account_name = var.account_name
  project_name = var.project_name

  clusters = {
    postgresql = {
      # =======================================================================
      # ENGINE CONFIGURATION
      # =======================================================================

      engine         = "aurora-postgresql"
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
      # CLOUDWATCH LOGS (PostgreSQL)
      # =======================================================================

      enabled_cloudwatch_logs_exports = [
        "postgresql" # PostgreSQL logs
      ]

      # =======================================================================
      # CLUSTER PARAMETERS (PostgreSQL-specific)
      # =======================================================================

      cluster_parameter_group = {
        family      = "aurora-postgresql14"
        description = "Custom cluster parameters for Aurora PostgreSQL"
        parameters = [
          # ===================================================================
          # EXTENSIONS AND LIBRARIES
          # ===================================================================
          {
            name         = "shared_preload_libraries"
            value        = "pg_stat_statements,pgaudit,auto_explain"
            apply_method = "pending-reboot"
          },
          # ===================================================================
          # LOGICAL REPLICATION
          # ===================================================================
          {
            name         = "rds.logical_replication"
            value        = "1"
            apply_method = "pending-reboot"
          },
          # ===================================================================
          # QUERY PERFORMANCE AND LOGGING
          # ===================================================================
          {
            name         = "log_min_duration_statement"
            value        = "1000" # Log queries taking > 1 second
            apply_method = "immediate"
          },
          {
            name         = "log_statement"
            value        = "ddl" # Log DDL statements
            apply_method = "immediate"
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
          },
          {
            name         = "log_duration"
            value        = "0"
            apply_method = "immediate"
          },
          # ===================================================================
          # PERFORMANCE TUNING
          # ===================================================================
          {
            name         = "max_connections"
            value        = "1000"
            apply_method = "pending-reboot"
          },
          {
            name         = "work_mem"
            value        = "16384" # 16 MB in KB
            apply_method = "immediate"
          },
          {
            name         = "maintenance_work_mem"
            value        = "524288" # 512 MB in KB
            apply_method = "immediate"
          },
          {
            name         = "effective_cache_size"
            value        = "{DBInstanceClassMemory/2/8192}"
            apply_method = "immediate"
          },
          {
            name         = "random_page_cost"
            value        = "1.1" # Lower for SSD
            apply_method = "immediate"
          },
          # ===================================================================
          # STATISTICS AND ANALYSIS
          # ===================================================================
          {
            name         = "track_activity_query_size"
            value        = "4096"
            apply_method = "pending-reboot"
          },
          {
            name         = "default_statistics_target"
            value        = "100"
            apply_method = "immediate"
          },
          # ===================================================================
          # TIMEOUTS
          # ===================================================================
          {
            name         = "statement_timeout"
            value        = "0"
            apply_method = "immediate"
          },
          {
            name         = "idle_in_transaction_session_timeout"
            value        = "3600000"
            apply_method = "immediate"
          },
          # ===================================================================
          # AUTO EXPLAIN
          # ===================================================================
          {
            name         = "auto_explain.log_min_duration"
            value        = "1000"
            apply_method = "immediate"
          },
          {
            name         = "auto_explain.log_analyze"
            value        = "1"
            apply_method = "immediate"
          },
          {
            name         = "auto_explain.log_buffers"
            value        = "1"
            apply_method = "immediate"
          },
          {
            name         = "auto_explain.log_timing"
            value        = "1"
            apply_method = "immediate"
          },
          {
            name         = "auto_explain.log_triggers"
            value        = "1"
            apply_method = "immediate"
          },
          {
            name         = "auto_explain.log_verbose"
            value        = "0"
            apply_method = "immediate"
          },
          # ===================================================================
          # PGAUDIT
          # ===================================================================
          {
            name         = "pgaudit.log"
            value        = "ddl,role,read,write"
            apply_method = "immediate"
          },
          {
            name         = "pgaudit.log_catalog"
            value        = "0"
            apply_method = "immediate"
          }
        ]
      }

      # =======================================================================
      # DB INSTANCE PARAMETERS (PostgreSQL-specific)
      # =======================================================================

      db_parameter_group = {
        family      = "aurora-postgresql14"
        description = "Custom instance parameters for Aurora PostgreSQL"
        parameters = [
          {
            name         = "shared_buffers"
            value        = "{DBInstanceClassMemory/4/8192}"
            apply_method = "pending-reboot"
          },
          {
            name         = "max_prepared_transactions"
            value        = "100"
            apply_method = "pending-reboot"
          },
          {
            name         = "timezone"
            value        = "UTC"
            apply_method = "immediate"
          },
          {
            name         = "client_encoding"
            value        = "UTF8"
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
        Engine             = "aurora-postgresql"
        LogicalReplication = "Enabled"
        Extensions = join(",", compact([
          "pg_stat_statements",
          "pgaudit",
          "auto_explain",
          var.enable_pgvector ? "pgvector" : "",
          var.enable_postgis ? "postgis" : ""
        ]))
      })
    }
  }

  tags_common = var.tags
}
