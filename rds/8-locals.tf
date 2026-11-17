locals {
  # =============================================================================
  # Region Prefix Mapping
  # =============================================================================

  # NOTE: us-west-1, us-west-2, eu-west-1 and eu-central-1 keep their historical
  # codes (usw1, usw2, euw1, euc1). Changing them would rename, and therefore
  # recreate, every cluster and instance already deployed in those regions.
  # Use var.region_prefix to override.
  region_prefix_map = {
    # US Regions
    "us-east-1" = "ause1"
    "us-east-2" = "ause2"
    "us-west-1" = "usw1"
    "us-west-2" = "usw2"
    # EU Regions
    "eu-west-1"    = "euw1"
    "eu-west-2"    = "euwe2"
    "eu-west-3"    = "euwe3"
    "eu-central-1" = "euc1"
    "eu-central-2" = "euce2"
    "eu-north-1"   = "euno1"
    "eu-south-1"   = "euso1"
    "eu-south-2"   = "euso2"
    # AP Regions
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-southeast-3" = "apse3"
    "ap-southeast-4" = "apse4"
    "ap-southeast-5" = "apse5"
    "ap-southeast-6" = "apse6"
    "ap-southeast-7" = "apse7"
    "ap-northeast-1" = "apne1"
    "ap-northeast-2" = "apne2"
    "ap-northeast-3" = "apne3"
    "ap-south-1"     = "apso1"
    "ap-south-2"     = "apso2"
    "ap-east-1"      = "apea1"
    "ap-east-2"      = "apea2"
    # SA / MX Regions
    "sa-east-1"    = "saea1"
    "mx-central-1" = "mxce1"
    # CA Regions
    "ca-central-1" = "cace1"
    "ca-west-1"    = "cawe1"
    # ME Regions
    "me-south-1"   = "meso1"
    "me-central-1" = "mece1"
    # AF Regions
    "af-south-1" = "afso1"
    # IL Regions
    "il-central-1" = "ilce1"
  }

  region_prefix = var.region_prefix != null ? var.region_prefix : lookup(
    local.region_prefix_map,
    data.aws_region.current.region,
    data.aws_region.current.region
  )

  # Name prefix: includes region prefix with trailing dash, or empty string
  name_prefix = var.use_region_prefix ? "${local.region_prefix}-" : ""

  managed_by_tags = { ManagedBy = "Terraform" }

  # =============================================================================
  # Generated Names (truncated to AWS limits; trailing hyphens removed)
  # =============================================================================

  # Aurora cluster identifiers (max 63 characters)
  cluster_names = {
    for cluster_key, cluster in var.clusters :
    cluster_key => trimsuffix(substr("${local.name_prefix}cluster-${var.account_name}-${var.project_name}-${cluster_key}", 0, 63), "-")
  }

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
        identifier          = coalesce(instance.identifier, trimsuffix(substr("${local.name_prefix}instance-${var.account_name}-${var.project_name}-${cluster_key}-${instance_key}", 0, 63), "-"))
        publicly_accessible = coalesce(instance.publicly_accessible, cluster.publicly_accessible)

        # Monitoring settings (instance overrides cluster)
        monitoring_interval                   = coalesce(instance.monitoring_interval, cluster.monitoring_interval, 0)
        monitoring_role_arn                   = try(coalesce(instance.monitoring_role_arn, cluster.monitoring_role_arn), null)
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

  # See cloudwatch_log_groups_enhanced below.

  # =============================================================================
  # Monitoring IAM Roles
  # =============================================================================

  # Clusters that need monitoring role created: the cluster itself or any of its
  # instances enables Enhanced Monitoring without an explicit role ARN.
  monitoring_roles_to_create = {
    for cluster_key, cluster in var.clusters :
    cluster_key => cluster
    if cluster.create_monitoring_role && cluster.monitoring_role_arn == null && (
      cluster.monitoring_interval > 0 ||
      coalesce(cluster.cluster_monitoring_interval, 0) > 0 ||
      anytrue([for instance in values(cluster.instances) : coalesce(instance.monitoring_interval, 0) > 0 && instance.monitoring_role_arn == null])
    )
  }

  # IAM role names (max 64 characters)
  monitoring_role_names = {
    for cluster_key, cluster in var.clusters :
    cluster_key => trimsuffix(substr("${local.name_prefix}role-rds-monitoring-${var.account_name}-${var.project_name}-${cluster_key}", 0, 64), "-")
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
        identifier   = trimsuffix(substr("${local.name_prefix}endpoint-${var.account_name}-${var.project_name}-${cluster_key}-${endpoint_key}", 0, 63), "-")
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

  # Final snapshot identifiers. final_snapshot_identifier_prefix is used verbatim
  # when set; otherwise "<cluster>-final-<random hex>" with a suffix that is stable
  # across plans (random_id) and unique per cluster lifetime.
  final_snapshot_identifiers = {
    for cluster_key, cluster in var.clusters :
    cluster_key => cluster.skip_final_snapshot ? null : coalesce(
      cluster.final_snapshot_identifier_prefix,
      "${local.cluster_names[cluster_key]}-final-${try(random_id.cluster_snapshot[cluster_key].hex, "")}"
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
  # Managed Secret Rotation
  # =============================================================================

  cluster_secret_rotations = {
    for cluster_key, cluster in var.clusters :
    cluster_key => cluster
    if cluster.manage_master_user_password && cluster.is_primary_cluster && cluster.manage_master_user_password_rotation_automatically
  }

  instance_secret_rotations = {
    for inst_key, inst in var.instances :
    inst_key => inst
    if inst.manage_master_user_password && inst.replicate_source_db == null && inst.manage_master_user_password_rotation_automatically
  }

  # =============================================================================
  # Aurora Limitless - Shard Groups
  # =============================================================================

  shard_groups = {
    for cluster_key, cluster in var.clusters :
    cluster_key => merge(cluster.shard_group, {
      identifier = trimsuffix(substr("${local.cluster_names[cluster_key]}-${coalesce(cluster.shard_group.shard_identifier_suffix, "shard")}", 0, 63), "-")
    })
    if try(cluster.shard_group.enabled, false)
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
        Name = local.cluster_names[cluster_key]
      },
      local.managed_by_tags
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
        Name = gc.global_cluster_identifier
      },
      local.managed_by_tags
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
      db_proxy_name = trimsuffix(substr(lower(replace("${local.name_prefix}proxy-${var.account_name}-${var.project_name}-${proxy_key}", "_", "-")), 0, 60), "-")
      role_name     = trimsuffix(substr("${local.name_prefix}role-rds-proxy-${var.account_name}-${var.project_name}-${proxy_key}", 0, 64), "-")
    })
  }

  # Resolve secret ARNs for RDS Proxy IAM policies
  # When secret_arn is explicitly provided, use it directly.
  # When secret_arn is null and the proxy references a cluster/instance with
  # manage_master_user_password=true, resolve the secret ARN from the created resource.
  # Only create the policy when a valid secret ARN can be resolved.
  db_proxy_secrets_policies = {
    for proxy_key, proxy in var.db_proxies :
    proxy_key => {
      secret_arn = coalesce(
        proxy.auth.secret_arn,
        proxy.cluster_key != null ? try(aws_rds_cluster.this[proxy.cluster_key].master_user_secret[0].secret_arn, null) : null,
        proxy.instance_key != null ? try(aws_db_instance.this[proxy.instance_key].master_user_secret[0].secret_arn, null) : null
      )
      # Customer managed KMS key of the RDS-managed secret (null = aws/secretsmanager).
      # The ARN reported by RDS is preferred over the configured value (which may be a key ID or alias).
      kms_key_id = proxy.auth.secret_arn != null ? null : (
        proxy.cluster_key != null ? (
          try(var.clusters[proxy.cluster_key].master_user_secret_kms_key_id, null) == null ? null : try(aws_rds_cluster.this[proxy.cluster_key].master_user_secret[0].kms_key_id, var.clusters[proxy.cluster_key].master_user_secret_kms_key_id)
          ) : (
          try(var.instances[proxy.instance_key].master_user_secret_kms_key_id, null) == null ? null : try(aws_db_instance.this[proxy.instance_key].master_user_secret[0].kms_key_id, var.instances[proxy.instance_key].master_user_secret_kms_key_id)
        )
      )
    }
    if(
      proxy.auth.secret_arn != null ||
      (proxy.cluster_key != null && try(var.clusters[proxy.cluster_key].manage_master_user_password, false)) ||
      (proxy.instance_key != null && try(var.instances[proxy.instance_key].manage_master_user_password, false))
    )
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
      identifier          = coalesce(inst.identifier, trimsuffix(substr("${local.name_prefix}rds-${var.account_name}-${var.project_name}-${inst_key}", 0, 63), "-"))
      port                = coalesce(inst.port, lookup(local.instance_default_ports, inst.engine, 5432))
      is_read_replica     = inst.replicate_source_db != null
      is_self_replica     = inst.replicate_source_db != null ? startswith(coalesce(inst.replicate_source_db, ""), "self:") : false
      source_instance_key = inst.replicate_source_db != null && startswith(coalesce(inst.replicate_source_db, ""), "self:") ? trimprefix(inst.replicate_source_db, "self:") : null
      final_snapshot_id = inst.skip_final_snapshot ? null : coalesce(
        inst.final_snapshot_identifier,
        "${coalesce(inst.identifier, trimsuffix(substr("${local.name_prefix}rds-${var.account_name}-${var.project_name}-${inst_key}", 0, 63), "-"))}-final-${try(random_id.instance_snapshot[inst_key].hex, "")}"
      )
      merged_tags = merge(
        var.tags_common,
        inst.tags,
        {
          Name = coalesce(inst.identifier, trimsuffix(substr("${local.name_prefix}rds-${var.account_name}-${var.project_name}-${inst_key}", 0, 63), "-"))
        },
        local.managed_by_tags
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
        log_class         = inst.cloudwatch_log_class
        # RDS writes to /aws/rds/instance/<identifier>/<log type>: honour a custom identifier
        name = "/aws/rds/instance/${coalesce(inst.identifier, trimsuffix(substr("${local.name_prefix}rds-${var.account_name}-${var.project_name}-${inst_key}", 0, 63), "-"))}/${log_type}"
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

  instance_monitoring_role_names = {
    for inst_key, inst in var.instances :
    inst_key => trimsuffix(substr("${local.name_prefix}role-rds-mon-inst-${var.account_name}-${var.project_name}-${inst_key}", 0, 64), "-")
  }

  # =============================================================================
  # CloudWatch Log Groups with Log Class
  # =============================================================================

  # Cluster CloudWatch log groups. Not created when cluster_identifier_prefix is
  # used: the final cluster identifier (and so the log group RDS writes to) is
  # only known after apply.
  cloudwatch_log_groups_enhanced = merge([
    for cluster_key, cluster in var.clusters : {
      for log_type in cluster.enabled_cloudwatch_logs_exports :
      "${cluster_key}-${log_type}" => {
        cluster_key       = cluster_key
        log_type          = log_type
        retention_in_days = cluster.cloudwatch_log_group_retention_in_days
        kms_key_id        = cluster.cloudwatch_log_group_kms_key_id
        log_class         = cluster.cloudwatch_log_class
        name              = "/aws/rds/cluster/${local.cluster_names[cluster_key]}/${log_type}"
      }
    } if length(cluster.enabled_cloudwatch_logs_exports) > 0 && cluster.cluster_identifier_prefix == null
  ]...)
}
