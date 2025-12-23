# =============================================================================
# Aurora Provisioned Cluster Example
# =============================================================================

module "aurora" {
  source = "../../rds"

  account_name = var.account_name
  project_name = var.project_name

  # Common tags for all resources
  tags_common = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }

  # Aurora Clusters
  clusters = {
    # Production Aurora PostgreSQL Cluster
    prod = {
      engine         = "aurora-postgresql"
      engine_version = var.engine_version
      engine_mode    = "provisioned"

      # Database configuration
      database_name = var.database_name

      # Credentials
      master_username             = var.db_username
      manage_master_user_password = true
      # master_user_secret_kms_key_id = var.kms_key_id  # Optional: use custom KMS key

      # IAM database authentication
      iam_database_authentication_enabled = true

      # Network (Security groups must be created externally)
      vpc_security_group_ids = var.vpc_security_group_ids
      subnet_ids             = var.database_subnet_ids
      create_subnet_group    = true

      # Backup & Maintenance
      backup_retention_period      = 30
      preferred_backup_window      = "03:00-04:00"
      preferred_maintenance_window = "sun:04:00-sun:05:00"
      skip_final_snapshot          = false

      # Encryption
      storage_encrypted = true
      kms_key_id        = var.kms_key_id

      # Protection
      deletion_protection = true

      # Performance Insights
      performance_insights_enabled          = true
      performance_insights_retention_period = 7

      # Enhanced Monitoring
      monitoring_interval    = 60 # Enhanced monitoring every 60 seconds
      create_monitoring_role = true

      # CloudWatch Logs
      enabled_cloudwatch_logs_exports        = ["postgresql"]
      cloudwatch_log_group_retention_in_days = 30

      # Cluster parameter group
      cluster_parameter_group = {
        family      = "aurora-postgresql15"
        description = "Custom cluster parameter group for production"
        parameters = [
          {
            name         = "shared_preload_libraries"
            value        = "pg_stat_statements,auto_explain"
            apply_method = "pending-reboot"
          },
          {
            name         = "log_min_duration_statement"
            value        = "1000" # Log queries taking more than 1 second
            apply_method = "immediate"
          }
        ]
      }

      # DB parameter group (for instances)
      db_parameter_group = {
        family      = "aurora-postgresql15"
        description = "Custom DB parameter group for production instances"
        parameters = [
          {
            name         = "log_statement"
            value        = "all"
            apply_method = "immediate"
          }
        ]
      }

      # Cluster instances (heterogeneous configuration)
      instances = {
        writer = {
          instance_class      = var.writer_instance_class
          promotion_tier      = 0
          publicly_accessible = false
        }
        reader1 = {
          instance_class      = var.reader_instance_class
          promotion_tier      = 1
          publicly_accessible = false
        }
        reader2 = {
          instance_class      = var.reader_instance_class
          promotion_tier      = 2
          publicly_accessible = false
          # Override monitoring for this specific instance
          monitoring_interval = 30
        }
      }

      # Autoscaling for read replicas
      autoscaling = {
        enabled      = true
        min_capacity = var.autoscaling_min_capacity # Minimum readers
        max_capacity = var.autoscaling_max_capacity # Can scale up to 5 readers

        target_tracking_policies = {
          cpu = {
            target_metric      = "RDSReaderAverageCPUUtilization"
            target_value       = var.autoscaling_cpu_target
            scale_in_cooldown  = 300
            scale_out_cooldown = 60
            disable_scale_in   = false
          }
          connections = {
            target_metric      = "RDSReaderAverageDatabaseConnections"
            target_value       = 500
            scale_in_cooldown  = 300
            scale_out_cooldown = 60
            disable_scale_in   = false
          }
        }
      }

      # Custom endpoints
      endpoints = {
        analytics = {
          type           = "READER"
          static_members = [] # Will use all readers
        }
        reporting = {
          type             = "ANY"
          excluded_members = []
        }
      }

      # Tags specific to this cluster
      tags = {
        Cluster     = "production"
        Application = "main-app"
      }
    }
  }
}
