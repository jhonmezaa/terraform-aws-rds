locals {
  # =============================================================================
  # Region Prefix Mapping
  # =============================================================================

  region_prefix_map = {
    "us-east-1"      = "ause1"
    "us-east-2"      = "ause2"
    "us-west-1"      = "usw1"
    "us-west-2"      = "usw2"
    "eu-west-1"      = "euw1"
    "eu-central-1"   = "euc1"
    "ap-southeast-1" = "apse1"
    "ap-northeast-1" = "apne1"
  }

  region_prefix = var.region_prefix != null ? var.region_prefix : lookup(
    local.region_prefix_map,
    data.aws_region.current.id,
    data.aws_region.current.id
  )

  # Name prefix: includes region prefix with trailing dash, or empty string
  name_prefix = var.use_region_prefix ? "${local.region_prefix}-" : ""

  # =============================================================================
  # Cluster Instances Mapping
  # =============================================================================

  # Flatten all instances from all clusters into a single map
  cluster_instances = merge([
    for cluster_key, cluster in var.clusters : {
      for instance_key, instance in cluster.instances :
      "${cluster_key}-${instance_key}" => merge(instance, {
        cluster_key         = cluster_key
        instance_key        = instance_key
        cluster             = cluster
        identifier          = coalesce(instance.identifier, "${local.name_prefix}instance-${var.account_name}-${var.project_name}-${cluster_key}-${instance_key}")
        publicly_accessible = coalesce(instance.publicly_accessible, cluster.publicly_accessible)

        # Monitoring settings (instance overrides cluster)
        monitoring_interval                   = coalesce(instance.monitoring_interval, cluster.monitoring_interval, 0)
        performance_insights_enabled          = coalesce(instance.performance_insights_enabled, cluster.performance_insights_enabled)
        performance_insights_kms_key_id       = try(coalesce(instance.performance_insights_kms_key_id, cluster.performance_insights_kms_key_id), null)
        performance_insights_retention_period = coalesce(instance.performance_insights_retention_period, cluster.performance_insights_retention_period, 7)
      })
    }
  ]...)

  # =============================================================================
  # Subnet Group Logic
  # =============================================================================

  # Clusters that need subnet groups created
  subnet_groups_to_create = {
    for cluster_key, cluster in var.clusters :
    cluster_key => cluster
    if cluster.create_subnet_group && length(cluster.subnet_ids) > 0
  }

  # =============================================================================
  # Parameter Groups Logic
  # =============================================================================

  # Cluster parameter groups to create
  cluster_parameter_groups = {
    for cluster_key, cluster in var.clusters :
    cluster_key => cluster.cluster_parameter_group
    if cluster.cluster_parameter_group != null
  }

  # DB parameter groups to create
  db_parameter_groups = {
    for cluster_key, cluster in var.clusters :
    cluster_key => cluster.db_parameter_group
    if cluster.db_parameter_group != null
  }

  # =============================================================================
  # CloudWatch Log Groups
  # =============================================================================

  # Flatten log group configurations
  cloudwatch_log_groups = merge([
    for cluster_key, cluster in var.clusters : {
      for log_type in cluster.enabled_cloudwatch_logs_exports :
      "${cluster_key}-${log_type}" => {
        cluster_key       = cluster_key
        log_type          = log_type
        retention_in_days = cluster.cloudwatch_log_group_retention_in_days
        kms_key_id        = cluster.cloudwatch_log_group_kms_key_id
        name              = "/aws/rds/cluster/${local.name_prefix}cluster-${var.account_name}-${var.project_name}-${cluster_key}/${log_type}"
      }
    } if length(cluster.enabled_cloudwatch_logs_exports) > 0
  ]...)

  # =============================================================================
  # Monitoring IAM Roles
  # =============================================================================

  # Clusters that need monitoring role created
  monitoring_roles_to_create = {
    for cluster_key, cluster in var.clusters :
    cluster_key => cluster
    if cluster.create_monitoring_role && cluster.monitoring_interval > 0 && cluster.monitoring_role_arn == null
  }

  # =============================================================================
  # Custom Endpoints
  # =============================================================================

  # Flatten custom endpoints
  custom_endpoints = merge([
    for cluster_key, cluster in var.clusters : {
      for endpoint_key, endpoint in cluster.endpoints :
      "${cluster_key}-${endpoint_key}" => merge(endpoint, {
        cluster_key  = cluster_key
        endpoint_key = endpoint_key
        identifier   = "${local.name_prefix}endpoint-${var.account_name}-${var.project_name}-${cluster_key}-${endpoint_key}"
      })
    }
  ]...)

  # =============================================================================
  # IAM Role Associations
  # =============================================================================

  # Flatten IAM role associations
  iam_role_associations = merge([
    for cluster_key, cluster in var.clusters : {
      for role_key, role in cluster.iam_roles :
      "${cluster_key}-${role_key}" => merge(role, {
        cluster_key = cluster_key
        role_key    = role_key
      })
    }
  ]...)

  # =============================================================================
  # Autoscaling Configuration
  # =============================================================================

  # Clusters with autoscaling enabled
  autoscaling_clusters = {
    for cluster_key, cluster in var.clusters :
    cluster_key => cluster
    if try(cluster.autoscaling.enabled, false)
  }

  # =============================================================================
  # Activity Streams
  # =============================================================================

  # Clusters with activity stream enabled
  activity_streams = {
    for cluster_key, cluster in var.clusters :
    cluster_key => cluster.activity_stream
    if try(cluster.activity_stream.enabled, false)
  }

  # =============================================================================
  # Final Snapshot Identifiers
  # =============================================================================

  # Generate unique final snapshot identifiers with timestamp
  final_snapshot_identifiers = {
    for cluster_key, cluster in var.clusters :
    cluster_key => cluster.skip_final_snapshot ? null : coalesce(
      cluster.final_snapshot_identifier_prefix,
      "${local.name_prefix}cluster-${var.account_name}-${var.project_name}-${cluster_key}-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
    )
  }

  # =============================================================================
  # Port Defaults
  # =============================================================================

  # Default ports based on engine
  default_ports = {
    "aurora-mysql"      = 3306
    "aurora-postgresql" = 5432
    "aurora"            = 3306 # Legacy Aurora MySQL
  }

  # Cluster ports with defaults
  cluster_ports = {
    for cluster_key, cluster in var.clusters :
    cluster_key => coalesce(
      cluster.port,
      lookup(local.default_ports, cluster.engine, 3306)
    )
  }

  # =============================================================================
  # Merged Tags
  # =============================================================================

  # Merge common tags with cluster-specific tags
  cluster_tags = {
    for cluster_key, cluster in var.clusters :
    cluster_key => merge(
      var.tags_common,
      cluster.tags,
      {
        Name = "${local.name_prefix}cluster-${var.account_name}-${var.project_name}-${cluster_key}"
      }
    )
  }

  # =============================================================================
  # Global Clusters
  # =============================================================================

  # Global cluster tags
  global_cluster_tags = {
    for gc_key, gc in var.global_clusters :
    gc_key => merge(
      var.tags_common,
      gc.tags,
      {
        Name = "${local.name_prefix}globalcluster-${var.account_name}-${var.project_name}-${gc_key}"
      }
    )
  }

  # =============================================================================
  # RDS Proxy Configuration
  # =============================================================================

  # RDS Proxy configurations with cluster or instance references
  db_proxy_configs = {
    for proxy_key, proxy in var.db_proxies :
    proxy_key => merge(proxy, {
      proxy_key     = proxy_key
      cluster_key   = try(proxy.cluster_key, null)
      instance_key  = try(proxy.instance_key, null)
      db_proxy_name = lower(replace("${local.name_prefix}proxy-${var.account_name}-${var.project_name}-${proxy_key}", "_", "-"))
      role_arn      = aws_iam_role.rds_proxy[proxy_key].arn
    })
  }

  # =============================================================================
  # Enhanced Autoscaling - Split by Policy Type
  # =============================================================================

  # Target Tracking Scaling Policies
  autoscaling_target_tracking_policies = merge([
    for cluster_key, cluster in local.autoscaling_clusters : {
      for policy_key, policy in try(cluster.autoscaling.target_tracking_policies, {}) :
      "${cluster_key}-${policy_key}" => merge(policy, {
        cluster_key  = cluster_key
        policy_key   = policy_key
        policy_type  = "TargetTrackingScaling"
        min_capacity = cluster.autoscaling.min_capacity
        max_capacity = cluster.autoscaling.max_capacity
      })
    }
  ]...)

  # Step Scaling Policies
  autoscaling_step_scaling_policies = merge([
    for cluster_key, cluster in local.autoscaling_clusters : {
      for policy_key, policy in try(cluster.autoscaling.step_scaling_policies, {}) :
      "${cluster_key}-${policy_key}" => merge(policy, {
        cluster_key  = cluster_key
        policy_key   = policy_key
        policy_type  = "StepScaling"
        min_capacity = cluster.autoscaling.min_capacity
        max_capacity = cluster.autoscaling.max_capacity
      })
    }
  ]...)

  # Scheduled Actions
  autoscaling_scheduled_actions = merge([
    for cluster_key, cluster in local.autoscaling_clusters : {
      for action_key, action in try(cluster.autoscaling.scheduled_actions, {}) :
      "${cluster_key}-${action_key}" => merge(action, {
        cluster_key        = cluster_key
        action_key         = action_key
        resource_id        = "cluster:${aws_rds_cluster.this[cluster_key].cluster_identifier}"
        scalable_dimension = "rds:cluster:ReadReplicaCount"
      })
    }
  ]...)

  # =============================================================================
  # Standard RDS Instance - Default Ports
  # =============================================================================

  instance_default_ports = {
    "postgres"      = 5432
    "mysql"         = 3306
    "mariadb"       = 3306
    "oracle-ee"     = 1521
    "oracle-se2"    = 1521
    "sqlserver-ee"  = 1433
    "sqlserver-se"  = 1433
    "sqlserver-ex"  = 1433
    "sqlserver-web" = 1433
  }

  # =============================================================================
  # Standard RDS Instance - Enriched Configurations
  # =============================================================================

  db_instance_configs = {
    for inst_key, inst in var.instances :
    inst_key => merge(inst, {
      instance_key        = inst_key
      identifier          = coalesce(inst.identifier, "${local.name_prefix}rds-${var.account_name}-${var.project_name}-${inst_key}")
      port                = coalesce(inst.port, lookup(local.instance_default_ports, inst.engine, 5432))
      is_read_replica     = inst.replicate_source_db != null
      is_self_replica     = inst.replicate_source_db != null ? startswith(coalesce(inst.replicate_source_db, ""), "self:") : false
      source_instance_key = inst.replicate_source_db != null && startswith(coalesce(inst.replicate_source_db, ""), "self:") ? trimprefix(inst.replicate_source_db, "self:") : null
      final_snapshot_id = inst.skip_final_snapshot ? null : coalesce(
        inst.final_snapshot_identifier,
        "${local.name_prefix}rds-${var.account_name}-${var.project_name}-${inst_key}-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
      )
      merged_tags = merge(
        var.tags_common,
        inst.tags,
        {
          Name = "${local.name_prefix}rds-${var.account_name}-${var.project_name}-${inst_key}"
        }
      )
    })
  }

  # Primary instances (not self-referencing replicas)
  db_instance_primary_configs = {
    for inst_key, config in local.db_instance_configs :
    inst_key => config
    if !config.is_self_replica
  }

  # Self-referencing read replicas (reference another instance in this module)
  db_instance_replica_configs = {
    for inst_key, config in local.db_instance_configs :
    inst_key => config
    if config.is_self_replica
  }

  # =============================================================================
  # Standard RDS Instance - Subnet Groups
  # =============================================================================

  instance_subnet_groups_to_create = {
    for inst_key, inst in var.instances :
    inst_key => inst
    if inst.create_subnet_group && length(inst.subnet_ids) > 0 && inst.replicate_source_db == null
  }

  # =============================================================================
  # Standard RDS Instance - Parameter Groups
  # =============================================================================

  instance_parameter_groups = {
    for inst_key, inst in var.instances :
    inst_key => inst.parameter_group
    if inst.parameter_group != null
  }

  # =============================================================================
  # Standard RDS Instance - Option Groups
  # =============================================================================

  instance_option_groups = {
    for inst_key, inst in var.instances :
    inst_key => merge(inst.option_group, {
      engine_name = coalesce(try(inst.option_group.engine_name, null), inst.engine)
    })
    if inst.option_group != null
  }

  # =============================================================================
  # Standard RDS Instance - CloudWatch Log Groups
  # =============================================================================

  instance_cloudwatch_log_groups = merge([
    for inst_key, inst in var.instances : {
      for log_type in inst.enabled_cloudwatch_logs_exports :
      "${inst_key}-${log_type}" => {
        instance_key      = inst_key
        log_type          = log_type
        retention_in_days = inst.cloudwatch_log_group_retention_in_days
        kms_key_id        = inst.cloudwatch_log_group_kms_key_id
        name              = "/aws/rds/instance/${local.name_prefix}rds-${var.account_name}-${var.project_name}-${inst_key}/${log_type}"
      }
    } if length(inst.enabled_cloudwatch_logs_exports) > 0
  ]...)

  # =============================================================================
  # Standard RDS Instance - Monitoring Roles
  # =============================================================================

  instance_monitoring_roles_to_create = {
    for inst_key, inst in var.instances :
    inst_key => inst
    if inst.create_monitoring_role && inst.monitoring_interval > 0 && inst.monitoring_role_arn == null
  }

  # =============================================================================
  # CloudWatch Log Groups with Log Class
  # =============================================================================

  # Enhanced CloudWatch log groups with log_class attribute
  cloudwatch_log_groups_enhanced = merge([
    for cluster_key, cluster in var.clusters : {
      for log_type in cluster.enabled_cloudwatch_logs_exports :
      "${cluster_key}-${log_type}" => {
        cluster_key       = cluster_key
        log_type          = log_type
        retention_in_days = cluster.cloudwatch_log_group_retention_in_days
        kms_key_id        = cluster.cloudwatch_log_group_kms_key_id
        log_class         = cluster.cloudwatch_log_class
        name              = "/aws/rds/cluster/${local.name_prefix}cluster-${var.account_name}-${var.project_name}-${cluster_key}/${log_type}"
      }
    } if length(cluster.enabled_cloudwatch_logs_exports) > 0
  ]...)
}
