# =============================================================================
# Aurora Advanced Autoscaling Example
# =============================================================================
# This example demonstrates advanced autoscaling patterns for Aurora:
# - Target tracking autoscaling (CPU and Connections)
# - Step scaling policies (fine-grained control)
# - Scheduled actions (business hours vs off-hours)
# - Multiple autoscaling triggers
# =============================================================================

module "aurora_autoscaling" {
  source = "../../rds"

  account_name = var.account_name
  project_name = var.project_name

  clusters = {
    autoscaling = {
      # Engine Configuration
      engine         = "aurora-postgresql"
      engine_version = var.engine_version
      engine_mode    = "provisioned"

      # Database
      database_name = var.database_name

      # Credentials (AWS Secrets Manager)
      master_username             = var.db_username
      manage_master_user_password = true

      # Network
      vpc_security_group_ids = var.vpc_security_group_ids
      subnet_ids             = var.database_subnet_ids
      create_subnet_group    = true

      # Backup
      backup_retention_period = 7
      skip_final_snapshot     = true

      # Encryption
      storage_encrypted = true

      # Performance Insights
      performance_insights_enabled          = true
      performance_insights_retention_period = 7

      # CloudWatch Logs
      enabled_cloudwatch_logs_exports = ["postgresql"]

      # Instances (1 writer + dynamic readers via autoscaling)
      instances = {
        writer = {
          instance_class      = var.instance_class
          publicly_accessible = false
          promotion_tier      = 0 # Writer instance
        }
      }

      # =======================================================================
      # ADVANCED AUTOSCALING CONFIGURATION
      # =======================================================================

      autoscaling = {
        # Enable autoscaling with capacity limits
        enabled      = true
        min_capacity = var.min_capacity
        max_capacity = var.max_capacity

        # Target Tracking Policies
        target_tracking_policies = {
          # Policy 1: CPU-based autoscaling (primary trigger)
          cpu = {
            target_metric      = "RDSReaderAverageCPUUtilization"
            target_value       = var.cpu_target_value
            scale_in_cooldown  = var.scale_in_cooldown
            scale_out_cooldown = var.scale_out_cooldown
            disable_scale_in   = false
          }

          # Policy 2: Connection-based autoscaling (secondary trigger)
          connections = {
            target_metric      = "RDSReaderAverageDatabaseConnections"
            target_value       = var.connections_target_value
            scale_in_cooldown  = 600 # Longer cooldown for connection-based scaling
            scale_out_cooldown = 120
            disable_scale_in   = false
          }
        }

        # Step Scaling Policies (fine-grained control for extreme scenarios)
        step_scaling_policies = {
          # Scale out aggressively when CPU is very high
          cpu_high = {
            adjustment_type         = "PercentChangeInCapacity"
            metric_aggregation_type = "Average"
            cooldown                = 60
            step_adjustments = [
              {
                scaling_adjustment          = 50 # Add 50% capacity
                metric_interval_lower_bound = 0  # When CPU > threshold
                metric_interval_upper_bound = 10 # And CPU <= threshold + 10
              },
              {
                scaling_adjustment          = 100 # Double capacity
                metric_interval_lower_bound = 10  # When CPU > threshold + 10
                metric_interval_upper_bound = null
              }
            ]
            # CloudWatch alarm that triggers this policy
            alarm = {
              comparison_operator = "GreaterThanThreshold"
              evaluation_periods  = 2
              metric_name         = "CPUUtilization"
              namespace           = "AWS/RDS"
              period              = 60
              statistic           = "Average"
              threshold           = 80
            }
          }
        }

        # Scheduled Actions (business hours vs off-hours)
        scheduled_actions = {
          # Scale UP for business hours (8 AM Mon-Fri)
          business_hours_start = {
            schedule     = var.business_hours_start
            min_capacity = var.business_hours_min_capacity
            max_capacity = var.business_hours_max_capacity
            timezone     = "UTC"
          }

          # Scale DOWN for off-hours (6 PM Mon-Fri)
          business_hours_end = {
            schedule     = var.business_hours_end
            min_capacity = var.off_hours_min_capacity
            max_capacity = var.off_hours_max_capacity
            timezone     = "UTC"
          }

          # Weekend scale down (Saturday 12 AM)
          weekend_start = {
            schedule     = "cron(0 0 ? * SAT *)"
            min_capacity = 1
            max_capacity = 2
            timezone     = "UTC"
          }

          # Monday morning scale up (Monday 6 AM - prepare for business)
          monday_morning = {
            schedule     = "cron(0 6 ? * MON *)"
            min_capacity = var.business_hours_min_capacity
            max_capacity = var.business_hours_max_capacity
            timezone     = "UTC"
          }
        }
      }

      tags = merge(var.tags, {
        Autoscaling = "Advanced"
      })
    }
  }

  tags_common = var.tags
}
