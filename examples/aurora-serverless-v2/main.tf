module "aurora_serverless" {
  source = "../../rds"

  account_name = var.account_name
  project_name = var.project_name

  # Common tags
  tags_common = {
    Environment = "development"
    ManagedBy   = "Terraform"
  }

  clusters = {
    # Serverless v2 Cluster for Development
    serverlessv2 = {
      engine         = "aurora-postgresql"
      engine_version = var.engine_version
      engine_mode    = "provisioned" # Serverless v2 uses provisioned mode

      # Database
      database_name = var.database_name

      # Managed password
      master_username             = var.db_username
      manage_master_user_password = true

      # Network (Security groups must be created externally)
      vpc_security_group_ids = var.vpc_security_group_ids
      subnet_ids             = var.database_subnet_ids
      create_subnet_group    = true

      # Backup (shorter retention for dev)
      backup_retention_period      = 7
      preferred_backup_window      = "03:00-04:00"
      preferred_maintenance_window = "sun:04:00-sun:05:00"
      skip_final_snapshot          = true # Dev environment

      # Encryption
      storage_encrypted = true

      # Protection (disabled for dev)
      deletion_protection = false

      # Enhanced Monitoring (less frequent for cost savings)
      monitoring_interval    = 0 # Disable enhanced monitoring for dev
      create_monitoring_role = false

      # CloudWatch Logs
      enabled_cloudwatch_logs_exports        = ["postgresql"]
      cloudwatch_log_group_retention_in_days = 7

      # Serverless v2 scaling configuration
      serverlessv2_scaling_configuration = {
        min_capacity = var.min_capacity # Minimum ACUs (cost-effective for dev)
        max_capacity = var.max_capacity # Maximum ACUs
      }

      # Performance Insights
      performance_insights_enabled          = true
      performance_insights_retention_period = 7

      # Serverless v2 instances
      instances = {
        writer = {
          instance_class      = "db.serverless" # Serverless v2 instance class
          promotion_tier      = 0
          publicly_accessible = false
        }
        reader = {
          instance_class      = "db.serverless"
          promotion_tier      = 1
          publicly_accessible = false
        }
      }

      # Tags
      tags = merge(var.tags, {
        Environment = "development"
        Purpose     = "Serverless v2 Development"
      })
    }
  }
}
