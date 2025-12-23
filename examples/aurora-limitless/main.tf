# =============================================================================
# Aurora Limitless Database Example
# =============================================================================
# This example demonstrates Aurora Limitless Database for horizontal scaling
# with PostgreSQL 15.5+
# =============================================================================

module "aurora_limitless" {
  source = "../../rds"

  account_name = var.account_name
  project_name = var.project_name

  clusters = {
    limitless = {
      # Engine Configuration - PostgreSQL 15.5+ required for Limitless
      engine                   = "aurora-postgresql"
      engine_version           = var.engine_version
      engine_mode              = "provisioned"
      cluster_scalability_type = "limitless" # Enable Aurora Limitless Database

      # Database Configuration
      database_name = "limitless_db"

      # Credentials (AWS Secrets Manager managed)
      master_username             = var.db_username
      manage_master_user_password = true

      # Network Configuration
      vpc_security_group_ids = var.vpc_security_group_ids
      subnet_ids             = var.database_subnet_ids
      create_subnet_group    = true
      publicly_accessible    = false

      # Aurora Limitless Shard Group Configuration
      shard_group = {
        enabled            = true
        max_acu            = var.max_acu            # 768 to 3145728 (0.75 TB to 3072 TB)
        min_acu            = var.min_acu            # Minimum capacity
        compute_redundancy = var.compute_redundancy # 0, 1, or 2 (2 = high availability)
      }

      # Backup Configuration
      backup_retention_period = 7
      skip_final_snapshot     = true # Set to false in production

      # Encryption
      storage_encrypted = true

      # Deletion Protection - Enable in production
      deletion_protection = false

      # Performance Insights
      performance_insights_enabled          = true
      performance_insights_retention_period = 7

      # CloudWatch Logs
      enabled_cloudwatch_logs_exports = ["postgresql"]
      cloudwatch_log_class            = "STANDARD"

      # Cluster Instances
      instances = {
        for i in range(var.instance_count) :
        "instance-${i + 1}" => {
          instance_class      = var.instance_class
          publicly_accessible = false
          promotion_tier      = i

          # Performance Insights per instance
          performance_insights_enabled          = true
          performance_insights_retention_period = 7
        }
      }

      # Tags
      tags = var.tags
    }
  }

  tags_common = var.tags
}
