# =============================================================================
# Aurora Global Cluster Example (Multi-Region Disaster Recovery)
# =============================================================================
# This example demonstrates Aurora Global Database with:
# - Primary cluster in us-east-1
# - Secondary cluster in us-west-2
# - Cross-region replication
# - Write forwarding from secondary to primary
# =============================================================================

# =============================================================================
# PRIMARY REGION (us-east-1)
# =============================================================================

# Primary Global Cluster and Aurora Cluster
module "aurora_primary" {
  source = "../../rds"

  providers = {
    aws = aws.primary
  }

  account_name = var.account_name
  project_name = "${var.project_name}-primary"

  # Global Cluster Configuration
  global_clusters = {
    main = {
      global_cluster_identifier = "${var.account_name}-${var.project_name}-global"
      engine                    = "aurora-postgresql"
      engine_version            = var.engine_version
      database_name             = var.database_name
      storage_encrypted         = true
      deletion_protection       = var.deletion_protection
    }
  }

  # Primary Aurora Cluster
  clusters = {
    primary = {
      # Engine
      engine         = "aurora-postgresql"
      engine_version = var.engine_version
      engine_mode    = "provisioned"

      # Database
      database_name = var.database_name

      # Credentials (AWS Secrets Manager)
      master_username             = var.db_username
      manage_master_user_password = true

      # Network
      vpc_security_group_ids = var.primary_vpc_security_group_ids
      subnet_ids             = var.primary_database_subnet_ids
      create_subnet_group    = true

      # Global Database Configuration
      global_cluster_identifier      = "${var.account_name}-${var.project_name}-global"
      is_primary_cluster             = true
      enable_global_write_forwarding = false # Primary handles writes
      enable_local_write_forwarding  = false

      # Backup
      backup_retention_period = 7
      skip_final_snapshot     = !var.deletion_protection

      # Encryption
      storage_encrypted = true

      # Deletion Protection
      deletion_protection = var.deletion_protection

      # Performance Insights
      performance_insights_enabled          = true
      performance_insights_retention_period = 7

      # CloudWatch Logs
      enabled_cloudwatch_logs_exports = ["postgresql"]

      # Instances
      instances = {
        writer = {
          instance_class      = var.instance_class
          publicly_accessible = false
          promotion_tier      = 0 # Writer instance
        }
        reader = {
          instance_class      = var.instance_class
          publicly_accessible = false
          promotion_tier      = 1 # Reader instance
        }
      }

      tags = merge(var.tags, {
        Region = var.primary_region
        Role   = "Primary"
      })
    }
  }

  tags_common = var.tags
}

# =============================================================================
# SECONDARY REGION (us-west-2)
# =============================================================================

# Secondary Aurora Cluster (Read Replica)
module "aurora_secondary" {
  source = "../../rds"

  providers = {
    aws = aws.secondary
  }

  account_name = var.account_name
  project_name = "${var.project_name}-secondary"

  clusters = {
    secondary = {
      # Engine
      engine         = "aurora-postgresql"
      engine_version = var.engine_version
      engine_mode    = "provisioned"

      # Database name is inherited from global cluster
      database_name = null

      # Credentials managed by global cluster
      manage_master_user_password = false
      master_username             = null
      master_password             = null

      # Network
      vpc_security_group_ids = var.secondary_vpc_security_group_ids
      subnet_ids             = var.secondary_database_subnet_ids
      create_subnet_group    = true

      # Global Database Configuration
      global_cluster_identifier      = "${var.account_name}-${var.project_name}-global"
      is_primary_cluster             = false
      enable_global_write_forwarding = true # Forward writes to primary
      enable_local_write_forwarding  = false

      # Backup (managed by global cluster)
      backup_retention_period = 7
      skip_final_snapshot     = !var.deletion_protection

      # Encryption
      storage_encrypted = true

      # Deletion Protection
      deletion_protection = var.deletion_protection

      # Performance Insights
      performance_insights_enabled          = true
      performance_insights_retention_period = 7

      # CloudWatch Logs
      enabled_cloudwatch_logs_exports = ["postgresql"]

      # Instances
      instances = {
        reader1 = {
          instance_class      = var.instance_class
          publicly_accessible = false
          promotion_tier      = 0 # Can be promoted to writer
        }
        reader2 = {
          instance_class      = var.instance_class
          publicly_accessible = false
          promotion_tier      = 1
        }
      }

      tags = merge(var.tags, {
        Region = var.secondary_region
        Role   = "Secondary"
      })
    }
  }

  tags_common = var.tags

  depends_on = [module.aurora_primary]
}
