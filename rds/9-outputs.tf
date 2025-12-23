# =============================================================================
# Aurora Cluster Outputs
# =============================================================================

output "cluster_ids" {
  description = "Map of cluster keys to cluster identifiers"
  value = {
    for k, v in aws_rds_cluster.this : k => v.id
  }
}

output "cluster_arns" {
  description = "Map of cluster keys to cluster ARNs"
  value = {
    for k, v in aws_rds_cluster.this : k => v.arn
  }
}

output "cluster_resource_ids" {
  description = "Map of cluster keys to cluster resource IDs"
  value = {
    for k, v in aws_rds_cluster.this : k => v.cluster_resource_id
  }
}

output "cluster_endpoints" {
  description = "Map of cluster keys to writer endpoints"
  value = {
    for k, v in aws_rds_cluster.this : k => v.endpoint
  }
}

output "cluster_reader_endpoints" {
  description = "Map of cluster keys to reader endpoints"
  value = {
    for k, v in aws_rds_cluster.this : k => v.reader_endpoint
  }
}

output "cluster_ports" {
  description = "Map of cluster keys to ports"
  value = {
    for k, v in aws_rds_cluster.this : k => v.port
  }
}

output "cluster_database_names" {
  description = "Map of cluster keys to database names"
  value = {
    for k, v in aws_rds_cluster.this : k => v.database_name
  }
}

output "cluster_master_usernames" {
  description = "Map of cluster keys to master usernames"
  value = {
    for k, v in aws_rds_cluster.this : k => v.master_username
  }
  sensitive = true
}

output "cluster_hosted_zone_ids" {
  description = "Map of cluster keys to hosted zone IDs"
  value = {
    for k, v in aws_rds_cluster.this : k => v.hosted_zone_id
  }
}

output "cluster_engine_versions" {
  description = "Map of cluster keys to actual engine versions"
  value = {
    for k, v in aws_rds_cluster.this : k => v.engine_version_actual
  }
}

output "cluster_members" {
  description = "Map of cluster keys to lists of member instance identifiers"
  value = {
    for k, v in aws_rds_cluster.this : k => v.cluster_members
  }
}

# =============================================================================
# Managed Password Secrets
# =============================================================================

output "cluster_master_user_secret_arns" {
  description = "Map of cluster keys to ARNs of Secrets Manager secrets for master user passwords (when manage_master_user_password is true)"
  value = {
    for k, v in aws_rds_cluster.this : k => try(v.master_user_secret[0].secret_arn, null)
  }
  sensitive = true
}

output "cluster_master_user_secret_kms_key_ids" {
  description = "Map of cluster keys to KMS key IDs used to encrypt master user secrets"
  value = {
    for k, v in aws_rds_cluster.this : k => try(v.master_user_secret[0].kms_key_id, null)
  }
}

# =============================================================================
# Cluster Instance Outputs
# =============================================================================

output "cluster_instance_ids" {
  description = "Map of instance keys to instance identifiers"
  value = {
    for k, v in aws_rds_cluster_instance.this : k => v.id
  }
}

output "cluster_instance_arns" {
  description = "Map of instance keys to instance ARNs"
  value = {
    for k, v in aws_rds_cluster_instance.this : k => v.arn
  }
}

output "cluster_instance_endpoints" {
  description = "Map of instance keys to instance endpoints"
  value = {
    for k, v in aws_rds_cluster_instance.this : k => v.endpoint
  }
}

output "cluster_instance_availability_zones" {
  description = "Map of instance keys to availability zones"
  value = {
    for k, v in aws_rds_cluster_instance.this : k => v.availability_zone
  }
}

# =============================================================================
# Custom Endpoint Outputs
# =============================================================================

output "custom_endpoint_ids" {
  description = "Map of endpoint keys to custom endpoint identifiers"
  value = {
    for k, v in aws_rds_cluster_endpoint.this : k => v.id
  }
}

output "custom_endpoint_arns" {
  description = "Map of endpoint keys to custom endpoint ARNs"
  value = {
    for k, v in aws_rds_cluster_endpoint.this : k => v.arn
  }
}

output "custom_endpoints" {
  description = "Map of endpoint keys to custom endpoint addresses"
  value = {
    for k, v in aws_rds_cluster_endpoint.this : k => v.endpoint
  }
}

# =============================================================================
# Subnet Group Outputs
# =============================================================================

output "db_subnet_group_names" {
  description = "Map of cluster keys to subnet group names"
  value = {
    for k, v in aws_db_subnet_group.this : k => v.name
  }
}

output "db_subnet_group_arns" {
  description = "Map of cluster keys to subnet group ARNs"
  value = {
    for k, v in aws_db_subnet_group.this : k => v.arn
  }
}

# =============================================================================
# Parameter Group Outputs
# =============================================================================

output "cluster_parameter_group_ids" {
  description = "Map of cluster keys to cluster parameter group IDs"
  value = {
    for k, v in aws_rds_cluster_parameter_group.this : k => v.id
  }
}

output "cluster_parameter_group_arns" {
  description = "Map of cluster keys to cluster parameter group ARNs"
  value = {
    for k, v in aws_rds_cluster_parameter_group.this : k => v.arn
  }
}

output "db_parameter_group_ids" {
  description = "Map of cluster keys to DB parameter group IDs"
  value = {
    for k, v in aws_db_parameter_group.this : k => v.id
  }
}

output "db_parameter_group_arns" {
  description = "Map of cluster keys to DB parameter group ARNs"
  value = {
    for k, v in aws_db_parameter_group.this : k => v.arn
  }
}

# =============================================================================
# CloudWatch Log Group Outputs
# =============================================================================

output "cloudwatch_log_group_names" {
  description = "Map of log group keys to CloudWatch log group names"
  value = {
    for k, v in aws_cloudwatch_log_group.this : k => v.name
  }
}

output "cloudwatch_log_group_arns" {
  description = "Map of log group keys to CloudWatch log group ARNs"
  value = {
    for k, v in aws_cloudwatch_log_group.this : k => v.arn
  }
}

# =============================================================================
# Monitoring Role Outputs
# =============================================================================

output "monitoring_role_arns" {
  description = "Map of cluster keys to monitoring IAM role ARNs"
  value = {
    for k, v in aws_iam_role.monitoring : k => v.arn
  }
}

output "monitoring_role_names" {
  description = "Map of cluster keys to monitoring IAM role names"
  value = {
    for k, v in aws_iam_role.monitoring : k => v.name
  }
}

# =============================================================================
# Activity Stream Outputs
# =============================================================================

output "activity_stream_kinesis_stream_names" {
  description = "Map of cluster keys to activity stream Kinesis stream names"
  value = {
    for k, v in aws_rds_cluster_activity_stream.this : k => v.kinesis_stream_name
  }
}

# =============================================================================
# Autoscaling Outputs
# =============================================================================

output "autoscaling_target_ids" {
  description = "Map of cluster keys to autoscaling target IDs"
  value = {
    for k, v in aws_appautoscaling_target.this : k => v.id
  }
}

output "autoscaling_target_tracking_policy_arns" {
  description = "Map of policy keys to target tracking autoscaling policy ARNs"
  value = {
    for k, v in aws_appautoscaling_policy.target_tracking : k => v.arn
  }
}

output "autoscaling_target_tracking_policy_names" {
  description = "Map of policy keys to target tracking autoscaling policy names"
  value = {
    for k, v in aws_appautoscaling_policy.target_tracking : k => v.name
  }
}

output "autoscaling_step_scaling_policy_arns" {
  description = "Map of policy keys to step scaling autoscaling policy ARNs"
  value = {
    for k, v in aws_appautoscaling_policy.step_scaling : k => v.arn
  }
}

output "autoscaling_step_scaling_policy_names" {
  description = "Map of policy keys to step scaling autoscaling policy names"
  value = {
    for k, v in aws_appautoscaling_policy.step_scaling : k => v.name
  }
}

output "autoscaling_scheduled_action_names" {
  description = "Map of action keys to scheduled action names"
  value = {
    for k, v in aws_appautoscaling_scheduled_action.this : k => v.name
  }
}

# =============================================================================
# Global Cluster Outputs
# =============================================================================

output "global_cluster_ids" {
  description = "Map of global cluster keys to global cluster identifiers"
  value = {
    for k, v in aws_rds_global_cluster.this : k => v.id
  }
}

output "global_cluster_arns" {
  description = "Map of global cluster keys to global cluster ARNs"
  value = {
    for k, v in aws_rds_global_cluster.this : k => v.arn
  }
}

output "global_cluster_resource_ids" {
  description = "Map of global cluster keys to global cluster resource IDs"
  value = {
    for k, v in aws_rds_global_cluster.this : k => v.global_cluster_resource_id
  }
}

output "global_cluster_members" {
  description = "Map of global cluster keys to lists of member cluster ARNs"
  value = {
    for k, v in aws_rds_global_cluster.this : k => v.global_cluster_members
  }
}

# =============================================================================
# Aurora Limitless Database - Shard Group Outputs
# =============================================================================

# Note: Shard groups for Aurora Limitless are managed by cluster_scalability_type setting.
# There is no separate aws_rds_shard_group resource in the current AWS provider.
# Cluster configuration automatically handles shard group creation when
# cluster_scalability_type = "limitless" is set.

# =============================================================================
# RDS Proxy Outputs
# =============================================================================

output "db_proxy_ids" {
  description = "Map of proxy keys to RDS Proxy identifiers"
  value = {
    for k, v in aws_db_proxy.this : k => v.id
  }
}

output "db_proxy_arns" {
  description = "Map of proxy keys to RDS Proxy ARNs"
  value = {
    for k, v in aws_db_proxy.this : k => v.arn
  }
}

output "db_proxy_endpoints" {
  description = "Map of proxy keys to RDS Proxy endpoints"
  value = {
    for k, v in aws_db_proxy.this : k => v.endpoint
  }
}

output "db_proxy_names" {
  description = "Map of proxy keys to RDS Proxy names"
  value = {
    for k, v in aws_db_proxy.this : k => v.name
  }
}

# =============================================================================
# Cluster Configuration Outputs
# =============================================================================

output "cluster_scalability_types" {
  description = "Map of cluster keys to scalability types (standard or limitless)"
  value = {
    for k, v in aws_rds_cluster.this : k => try(v.cluster_scalability_type, "standard")
  }
}

output "cluster_ca_certificate_identifiers" {
  description = "Map of cluster keys to CA certificate identifiers"
  value = {
    for k, v in aws_rds_cluster.this : k => v.ca_certificate_identifier
  }
}

output "cluster_engine_lifecycle_support" {
  description = "Map of cluster keys to engine lifecycle support settings"
  value = {
    for k, v in aws_rds_cluster.this : k => try(v.engine_lifecycle_support, null)
  }
}

output "cluster_password_rotation_enabled" {
  description = "Map of cluster keys indicating whether automatic password rotation is enabled"
  value = {
    for k, v in aws_rds_cluster.this : k => try(v.rotate_master_user_password_automatically, false)
  }
}

output "cluster_password_rotation_schedule_days" {
  description = "Map of cluster keys to password rotation schedule in days"
  value = {
    for k, v in aws_rds_cluster.this : k => try(v.master_user_password_rotation_automatically_after_days, null)
  }
}

# =============================================================================
# CloudWatch Log Configuration Outputs
# =============================================================================

output "cloudwatch_log_groups_with_class" {
  description = "Map of log group keys to log group details including log class (STANDARD/INFREQUENT_ACCESS)"
  value = {
    for k, v in aws_cloudwatch_log_group.this : k => {
      name      = v.name
      arn       = v.arn
      log_class = try(v.tags["LogClass"], "STANDARD")
      retention = v.retention_in_days
    }
  }
}

# =============================================================================
# Utility Outputs
# =============================================================================

output "region" {
  description = "AWS region where resources are deployed"
  value       = data.aws_region.current.id
}

output "region_prefix" {
  description = "Region prefix used for resource naming"
  value       = local.region_prefix
}
