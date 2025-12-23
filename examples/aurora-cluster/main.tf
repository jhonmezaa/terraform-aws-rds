# =============================================================================
# Aurora MySQL Cluster Example
# =============================================================================

module "aurora_mysql" {
  source = "../../rds"

  account_name = var.account_name
  project_name = var.project_name

  tags_common = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }

  clusters = {
    # Production Aurora MySQL Cluster
    prod = {
      engine         = "aurora-mysql"
      engine_version = var.engine_version
      engine_mode    = "provisioned"

      database_name = var.database_name

      # Credentials
      master_username             = var.db_username
      manage_master_user_password = true

      # Network (Security groups must be created externally)
      vpc_security_group_ids = var.vpc_security_group_ids
      subnet_ids             = var.database_subnet_ids
      create_subnet_group    = true

      # Backup
      backup_retention_period      = 30
      preferred_backup_window      = "03:00-04:00"
      preferred_maintenance_window = "sun:04:00-sun:05:00"
      skip_final_snapshot          = false
      backtrack_window             = 259200 # 72 hours for MySQL

      # Security
      storage_encrypted   = true
      deletion_protection = true

      # Monitoring
      performance_insights_enabled          = true
      performance_insights_retention_period = 7
      monitoring_interval                   = 60
      create_monitoring_role                = true

      # Logs
      enabled_cloudwatch_logs_exports        = ["audit", "error", "general", "slowquery"]
      cloudwatch_log_group_retention_in_days = 30

      # Cluster parameter group
      cluster_parameter_group = {
        family      = "aurora-mysql8.0"
        description = "Custom cluster parameter group"
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
          }
        ]
      }

      # Instances
      instances = {
        writer = {
          instance_class      = var.instance_class
          promotion_tier      = 0
          publicly_accessible = false
        }
        reader1 = {
          instance_class      = var.instance_class
          promotion_tier      = 1
          publicly_accessible = false
        }
        reader2 = {
          instance_class      = var.instance_class
          promotion_tier      = 2
          publicly_accessible = false
        }
      }

      # Autoscaling
      autoscaling = {
        enabled      = true
        min_capacity = var.autoscaling_min_capacity
        max_capacity = var.autoscaling_max_capacity

        target_tracking_policies = {
          cpu = {
            target_metric      = "RDSReaderAverageCPUUtilization"
            target_value       = var.autoscaling_cpu_target
            scale_in_cooldown  = 300
            scale_out_cooldown = 60
            disable_scale_in   = false
          }
        }
      }

      tags = {
        Cluster = "production"
        Engine  = "mysql"
      }
    }
  }
}
