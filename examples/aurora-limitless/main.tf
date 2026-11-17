# =============================================================================
# Aurora Limitless Database Example
# =============================================================================
# This example demonstrates Aurora Limitless Database for horizontal scaling
# (Aurora PostgreSQL "-limitless" engine versions)
# =============================================================================

module "aurora_limitless" {
  source = "../../rds"

  account_name = var.account_name
  project_name = var.project_name

  clusters = {
    limitless = {
      # Engine Configuration - Limitless engine versions end in "-limitless"
      engine                   = "aurora-postgresql"
      engine_version           = var.engine_version
      storage_type             = "aurora-iopt1"
      cluster_scalability_type = "limitless" # Enable Aurora Limitless Database (engine_mode is sent empty)

      # Database Configuration
      database_name = "limitless_db"

      # Credentials: Aurora Limitless does not support RDS-managed master passwords
      master_username             = var.db_username
      manage_master_user_password = false
      master_password             = var.db_password

      # Network Configuration
      vpc_security_group_ids = var.vpc_security_group_ids
      subnet_ids             = var.database_subnet_ids
      create_subnet_group    = true
      publicly_accessible    = false

      # Aurora Limitless requires Enhanced Monitoring and Performance Insights
      # at cluster level (the monitoring IAM role is created by the module)
      cluster_monitoring_interval                   = 30
      cluster_performance_insights_enabled          = true
      cluster_performance_insights_retention_period = 31

      # Aurora Limitless Shard Group (aws_rds_shard_group)
      shard_group = {
        enabled            = true
        max_acu            = var.max_acu
        min_acu            = var.min_acu
        compute_redundancy = var.compute_redundancy # 0, 1, or 2 (2 = high availability)
      }

      # Backup Configuration
      backup_retention_period = 7
      skip_final_snapshot     = true # Set to false in production

      # Encryption
      storage_encrypted = true

      # Deletion Protection - Enable in production
      deletion_protection = false
      apply_immediately   = true

      # CloudWatch Logs
      enabled_cloudwatch_logs_exports = ["postgresql"]
      cloudwatch_log_class            = "STANDARD"

      # No cluster instances: a Limitless cluster serves traffic through its shard group

      # Tags
      tags = var.tags
    }
  }

  tags_common = var.tags
}
