# =============================================================================
# Common Variables
# =============================================================================

variable "create" {
  description = "Whether to create all resources (master toggle)"
  type        = bool
  default     = true
}

variable "account_name" {
  description = "Account name for resource naming"
  type        = string

  validation {
    condition     = length(var.account_name) >= 1 && length(var.account_name) <= 32
    error_message = "account_name debe tener entre 1 y 32 caracteres."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.account_name))
    error_message = "account_name solo puede contener letras minúsculas, números y guiones."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string

  validation {
    condition     = length(var.project_name) >= 1 && length(var.project_name) <= 32
    error_message = "project_name debe tener entre 1 y 32 caracteres."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name solo puede contener letras minúsculas, números y guiones."
  }
}

variable "region_prefix" {
  description = "Region prefix for resource naming (e.g., 'ause1', 'usw2'). If not provided, will be derived from current region"
  type        = string
  default     = null
}

variable "use_region_prefix" {
  description = "Whether to include the region prefix in resource names. When false, names omit the region prefix (e.g., 'rds-prod-myapp-primary' instead of 'ause1-rds-prod-myapp-primary')"
  type        = bool
  default     = true
}

variable "tags_common" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# Aurora Clusters Configuration
# =============================================================================

variable "clusters" {
  description = "Map of Aurora cluster configurations"
  type = map(object({
    # Engine Configuration
    engine                     = string
    engine_version             = optional(string)
    engine_mode                = optional(string, "provisioned") # provisioned, serverless
    engine_lifecycle_support   = optional(string)                # open-source-rds-extended-support, open-source-rds-extended-support-disabled
    cluster_scalability_type   = optional(string, "standard")    # standard, limitless (PostgreSQL 15.5+ only)
    cluster_ca_cert_identifier = optional(string)                # rds-ca-2019, rds-ca-rsa2048-g1, rds-ca-rsa4096-g1, rds-ca-ecc384-g1

    # Database Configuration
    database_name   = optional(string)
    master_username = optional(string)
    master_password = optional(string)
    port            = optional(number)

    # Credentials Management
    manage_master_user_password         = optional(bool, true)
    master_user_secret_kms_key_id       = optional(string)
    iam_database_authentication_enabled = optional(bool, false)

    # Password Rotation (when manage_master_user_password = true)
    manage_master_user_password_rotation_automatically = optional(bool, false)
    master_user_password_rotation_schedule_days        = optional(number)       # Alternative to schedule_expression
    master_user_password_rotation_schedule_expression  = optional(string)       # cron() or rate() expression
    master_user_password_rotation_duration             = optional(string, "3h") # Duration window (e.g., "3h", "6h")
    master_user_password_rotate_immediately            = optional(bool)         # Rotate as soon as the rotation is configured (AWS default: true)

    # Network Configuration
    vpc_security_group_ids = optional(list(string), [])
    subnet_ids             = optional(list(string), [])
    create_subnet_group    = optional(bool, true)
    db_subnet_group_name   = optional(string)
    network_type           = optional(string) # IPV4 or DUAL
    publicly_accessible    = optional(bool, false)
    availability_zones     = optional(list(string), [])

    # Backup & Maintenance
    backup_retention_period          = optional(number, 7)
    preferred_backup_window          = optional(string)
    preferred_maintenance_window     = optional(string)
    skip_final_snapshot              = optional(bool, true)
    final_snapshot_identifier_prefix = optional(string)
    snapshot_identifier              = optional(string) # Restore from snapshot
    copy_tags_to_snapshot            = optional(bool, true)
    backtrack_window                 = optional(number, 0) # 0-259200 seconds (72 hours)

    # Point-in-time Restore
    restore_to_point_in_time = optional(object({
      source_cluster_identifier  = optional(string)
      source_cluster_resource_id = optional(string)              # Alternative to source_cluster_identifier
      restore_type               = optional(string, "full-copy") # full-copy, copy-on-write
      use_latest_restorable_time = optional(bool, true)
      restore_to_time            = optional(string)
    }))

    # S3 Import (MySQL only)
    s3_import = optional(object({
      source_engine         = string
      source_engine_version = string
      bucket_name           = string
      bucket_prefix         = optional(string)
      ingestion_role        = string
    }))

    # Encryption
    storage_encrypted = optional(bool, true)
    kms_key_id        = optional(string)

    # Deletion Protection
    deletion_protection      = optional(bool, true)
    apply_immediately        = optional(bool, false)
    delete_automated_backups = optional(bool) # Delete automated backups when the cluster is deleted (AWS default: true)

    # Performance Insights (defaults for the cluster instances)
    performance_insights_enabled          = optional(bool, false)
    performance_insights_kms_key_id       = optional(string)
    performance_insights_retention_period = optional(number, 7)

    # Enhanced Monitoring
    enabled_cloudwatch_logs_exports        = optional(list(string), [])
    cloudwatch_log_group_retention_in_days = optional(number, 7)
    cloudwatch_log_group_kms_key_id        = optional(string)
    cloudwatch_log_class                   = optional(string, "STANDARD") # STANDARD or INFREQUENT_ACCESS (50% cost savings)

    monitoring_interval    = optional(number, 0) # 0, 1, 5, 10, 15, 30, 60 (default for the cluster instances)
    monitoring_role_arn    = optional(string)
    create_monitoring_role = optional(bool, true)

    # Cluster-level monitoring (set on aws_rds_cluster itself; needed by Multi-AZ DB clusters and Aurora Limitless)
    cluster_monitoring_interval                   = optional(number) # 0, 1, 5, 10, 15, 30, 60
    cluster_performance_insights_enabled          = optional(bool)
    cluster_performance_insights_kms_key_id       = optional(string)
    cluster_performance_insights_retention_period = optional(number)
    database_insights_mode                        = optional(string) # standard or advanced

    # Serverless v1 Configuration (engine_mode = "serverless")
    scaling_configuration = optional(object({
      auto_pause               = optional(bool, true)
      max_capacity             = optional(number, 2)
      min_capacity             = optional(number, 1)
      seconds_until_auto_pause = optional(number, 300)
      seconds_before_timeout   = optional(number)
      timeout_action           = optional(string, "RollbackCapacityChange")
    }))

    # Serverless v2 Configuration (engine_mode = "provisioned")
    serverlessv2_scaling_configuration = optional(object({
      max_capacity             = number
      min_capacity             = number
      seconds_until_auto_pause = optional(number) # Only when min_capacity = 0
    }))

    # Aurora Limitless Database (PostgreSQL 15.5+ only, requires cluster_scalability_type = "limitless")
    shard_group = optional(object({
      enabled                 = optional(bool, false)
      max_acu                 = number           # Maximum capacity of the DB shard group in ACUs
      min_acu                 = optional(number) # Minimum capacity of the DB shard group in ACUs
      publicly_accessible     = optional(bool, false)
      compute_redundancy      = optional(number, 2) # 0, 1, or 2 (0 = no compute redundancy)
      max_allocated_storage   = optional(number)    # DEPRECATED: not supported by aws_rds_shard_group, ignored
      min_allocated_storage   = optional(number)    # DEPRECATED: not supported by aws_rds_shard_group, ignored
      shard_identifier_suffix = optional(string)    # Custom suffix for shard group identifier (default: "shard")
      tags                    = optional(map(string), {})
      timeouts = optional(object({
        create = optional(string)
        update = optional(string)
        delete = optional(string)
      }))
    }))

    # Global Database
    global_cluster_identifier      = optional(string)
    is_primary_cluster             = optional(bool, true) # false = secondary cluster: database_name, master_username and credentials are not sent
    enable_global_write_forwarding = optional(bool, false)
    enable_local_write_forwarding  = optional(bool, false)

    # HTTP Endpoint (Data API for Serverless)
    enable_http_endpoint = optional(bool, false)

    # Cluster Parameter Group
    cluster_parameter_group = optional(object({
      name        = optional(string)
      family      = optional(string)
      description = optional(string, "Cluster parameter group")
      parameters = optional(list(object({
        name         = string
        value        = string
        apply_method = optional(string, "immediate")
      })), [])
    }))

    # DB Parameter Group (for instances)
    db_parameter_group = optional(object({
      name        = optional(string)
      family      = optional(string)
      description = optional(string, "DB parameter group")
      parameters = optional(list(object({
        name         = string
        value        = string
        apply_method = optional(string, "immediate")
      })), [])
    }))

    # Cluster Instances
    instances = optional(map(object({
      identifier                   = optional(string)
      instance_class               = string
      publicly_accessible          = optional(bool)
      promotion_tier               = optional(number, 0)
      availability_zone            = optional(string)
      preferred_maintenance_window = optional(string)

      # Monitoring per instance
      monitoring_interval                   = optional(number)
      monitoring_role_arn                   = optional(string)
      performance_insights_enabled          = optional(bool)
      performance_insights_kms_key_id       = optional(string)
      performance_insights_retention_period = optional(number)

      # Auto minor version upgrade
      auto_minor_version_upgrade = optional(bool, true)

      # CA certificate
      ca_cert_identifier = optional(string)

      # Copy tags from cluster
      copy_tags_to_snapshot = optional(bool)

      # Custom endpoint for this specific instance
      custom_iam_instance_profile = optional(string)

      # DEPRECATED: aws_rds_cluster_instance has no network_type argument, ignored
      network_type = optional(string)

      tags = optional(map(string), {})
    })), {})

    # Autoscaling Configuration
    autoscaling = optional(object({
      enabled      = optional(bool, false)
      min_capacity = optional(number, 1)
      max_capacity = optional(number, 5)

      # Target Tracking Scaling Policies
      target_tracking_policies = optional(map(object({
        target_metric      = optional(string, "RDSReaderAverageCPUUtilization") # or RDSReaderAverageDatabaseConnections
        target_value       = optional(number, 75)
        scale_in_cooldown  = optional(number, 300)
        scale_out_cooldown = optional(number, 300)
        disable_scale_in   = optional(bool, false)
        })), {
        cpu = {
          target_metric = "RDSReaderAverageCPUUtilization"
          target_value  = 75
        }
      })

      # Step Scaling Policies
      step_scaling_policies = optional(map(object({
        adjustment_type          = optional(string, "ChangeInCapacity") # ChangeInCapacity, PercentChangeInCapacity, ExactCapacity
        metric_aggregation_type  = optional(string, "Average")
        cooldown                 = optional(number, 300)
        min_adjustment_magnitude = optional(number)
        step_adjustments = list(object({
          scaling_adjustment          = number
          metric_interval_lower_bound = optional(number)
          metric_interval_upper_bound = optional(number)
        }))
        # CloudWatch alarm configuration for this policy
        alarm = object({
          comparison_operator = string # GreaterThanThreshold, LessThanThreshold, etc.
          evaluation_periods  = number
          metric_name         = string # CPUUtilization, DatabaseConnections, etc.
          namespace           = optional(string, "AWS/RDS")
          period              = number
          statistic           = optional(string, "Average")
          threshold           = number
        })
      })), {})

      # Scheduled Actions
      scheduled_actions = optional(map(object({
        schedule           = string # Cron expression
        min_capacity       = optional(number)
        max_capacity       = optional(number)
        timezone           = optional(string, "UTC")
        start_time         = optional(string)
        end_time           = optional(string)
        recurrence_pattern = optional(string) # DEPRECATED: not supported by aws_appautoscaling_scheduled_action, ignored
      })), {})

      # DEPRECATED: Application Auto Scaling has no predictive scaling for Aurora, ignored
      predictive_scaling_enabled = optional(bool, false)
    }))

    # Custom Endpoints
    endpoints = optional(map(object({
      type             = string # READER, WRITER, ANY
      static_members   = optional(list(string), [])
      excluded_members = optional(list(string), [])
      tags             = optional(map(string), {})
    })), {})

    # IAM Role Associations (for features like S3 import, Lambda, etc.)
    iam_roles = optional(map(object({
      role_arn     = string
      feature_name = string # S3_INTEGRATION, LAMBDA, COMPREHEND, etc.
    })), {})

    # Activity Stream
    activity_stream = optional(object({
      enabled                             = optional(bool, false)
      mode                                = optional(string, "async") # sync or async
      kms_key_id                          = string
      engine_native_audit_fields_included = optional(bool, false)
    }))

    # Domain Integration (Active Directory)
    domain               = optional(string)
    domain_iam_role_name = optional(string)

    # Allocated Storage / instance class (for Multi-AZ DB clusters)
    db_cluster_instance_class = optional(string)
    allocated_storage         = optional(number)
    storage_type              = optional(string)
    iops                      = optional(number)

    # Replication
    replication_source_identifier = optional(string)
    source_region                 = optional(string)

    # Allow major version upgrade
    allow_major_version_upgrade = optional(bool, false)

    # Database cluster identifier
    cluster_identifier_prefix = optional(string)

    # Timeouts
    timeouts = optional(object({
      create = optional(string, "120m")
      update = optional(string, "120m")
      delete = optional(string, "120m")
    }), {})

    # Tags specific to this cluster
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for cluster_key, cluster in var.clusters :
      !cluster.publicly_accessible
    ])
    error_message = "Hacer público un cluster Aurora es un riesgo de seguridad. Usa publicly_accessible = false."
  }

  validation {
    condition = alltrue([
      for cluster_key, cluster in var.clusters :
      cluster.backup_retention_period >= 1 && cluster.backup_retention_period <= 35
    ])
    error_message = "backup_retention_period del cluster debe estar entre 1 y 35 días."
  }

  validation {
    condition = alltrue([
      for cluster_key, cluster in var.clusters :
      cluster.engine_mode == "serverless" ? cluster.scaling_configuration != null : true
    ])
    error_message = "Con engine_mode = 'serverless' debes definir scaling_configuration."
  }

  validation {
    condition = alltrue([
      for cluster_key, cluster in var.clusters :
      cluster.backtrack_window >= 0 && cluster.backtrack_window <= 259200
    ])
    error_message = "backtrack_window debe estar entre 0 y 259200 segundos (72 horas)."
  }

  validation {
    condition = alltrue([
      for cluster_key, cluster in var.clusters :
      contains(["provisioned", "serverless", "parallelquery", "global"], cluster.engine_mode)
    ])
    error_message = "engine_mode debe ser uno de: provisioned, serverless, parallelquery, global."
  }

  validation {
    condition = alltrue([
      for cluster_key, cluster in var.clusters :
      contains(["standard", "limitless"], cluster.cluster_scalability_type)
    ])
    error_message = "cluster_scalability_type debe ser 'standard' o 'limitless'."
  }

  validation {
    condition = alltrue([
      for cluster_key, cluster in var.clusters :
      cluster.cluster_scalability_type == "limitless" ? try(cluster.shard_group.enabled, false) : true
    ])
    error_message = "Con cluster_scalability_type = 'limitless' debes definir shard_group."
  }

  validation {
    condition = alltrue([
      for cluster_key, cluster in var.clusters :
      contains(["STANDARD", "INFREQUENT_ACCESS"], cluster.cloudwatch_log_class)
    ])
    error_message = "cloudwatch_log_class debe ser 'STANDARD' o 'INFREQUENT_ACCESS'."
  }

  validation {
    condition = alltrue([
      for cluster_key, cluster in var.clusters :
      try(cluster.shard_group.enabled, false) == false || (
        cluster.shard_group.max_acu > 0 && cluster.shard_group.max_acu >= coalesce(cluster.shard_group.min_acu, 0)
      )
    ])
    error_message = "shard_group.max_acu debe ser mayor que 0 y mayor o igual que min_acu."
  }

  validation {
    condition = alltrue([
      for cluster_key, cluster in var.clusters :
      cluster.cluster_scalability_type == "limitless" || !try(cluster.shard_group.enabled, false)
    ])
    error_message = "shard_group solo se puede habilitar con cluster_scalability_type = 'limitless'."
  }

  validation {
    condition = alltrue([
      for cluster_key, cluster in var.clusters :
      !cluster.manage_master_user_password_rotation_automatically || (
        cluster.manage_master_user_password && (
          cluster.master_user_password_rotation_schedule_days != null ||
          cluster.master_user_password_rotation_schedule_expression != null
        )
      )
    ])
    error_message = "La rotación automática requiere manage_master_user_password = true y master_user_password_rotation_schedule_days o master_user_password_rotation_schedule_expression."
  }

  default = {}
}

# =============================================================================
# Standard RDS Instances Configuration
# =============================================================================

variable "instances" {
  description = "Map of standard RDS instance configurations (non-Aurora). Use 'clusters' for Aurora."
  type = map(object({
    # Identifier (custom name override)
    identifier = optional(string) # Custom RDS identifier. If null, auto-generated as: {region_prefix}-rds-{account}-{project}-{key}

    # Engine Configuration
    engine         = string
    engine_version = optional(string)
    license_model  = optional(string)

    # Instance Configuration
    instance_class = string

    # Storage Configuration
    allocated_storage     = optional(number)
    max_allocated_storage = optional(number)
    storage_type          = optional(string, "gp3")
    iops                  = optional(number)
    storage_throughput    = optional(number)

    # Database Configuration
    database_name = optional(string)
    port          = optional(number)

    # Credentials Management
    master_username                     = optional(string)
    master_password                     = optional(string)
    manage_master_user_password         = optional(bool, true)
    master_user_secret_kms_key_id       = optional(string)
    iam_database_authentication_enabled = optional(bool, false)

    # Password Rotation (when manage_master_user_password = true)
    manage_master_user_password_rotation_automatically = optional(bool, false)
    master_user_password_rotation_schedule_days        = optional(number)
    master_user_password_rotation_schedule_expression  = optional(string)
    master_user_password_rotation_duration             = optional(string, "3h")
    master_user_password_rotate_immediately            = optional(bool)

    # Network Configuration
    vpc_security_group_ids = optional(list(string), [])
    subnet_ids             = optional(list(string), [])
    create_subnet_group    = optional(bool, true)
    db_subnet_group_name   = optional(string)
    network_type           = optional(string)
    publicly_accessible    = optional(bool, false)
    availability_zone      = optional(string)
    multi_az               = optional(bool, false)

    # Engine extras
    engine_lifecycle_support = optional(string) # open-source-rds-extended-support, open-source-rds-extended-support-disabled
    timezone                 = optional(string) # SQL Server only
    dedicated_log_volume     = optional(bool)
    database_insights_mode   = optional(string) # standard or advanced

    # Backup & Maintenance
    backup_retention_period     = optional(number, 7)
    backup_window               = optional(string)
    backup_target               = optional(string)
    maintenance_window          = optional(string)
    auto_minor_version_upgrade  = optional(bool, true)
    allow_major_version_upgrade = optional(bool, false)
    apply_immediately           = optional(bool, false)

    # Deletion & Snapshot
    deletion_protection       = optional(bool, true)
    skip_final_snapshot       = optional(bool, true)
    final_snapshot_identifier = optional(string)
    delete_automated_backups  = optional(bool, true)
    copy_tags_to_snapshot     = optional(bool, true)

    # Snapshot Restore
    snapshot_identifier = optional(string)

    # Point-in-time Restore
    restore_to_point_in_time = optional(object({
      source_db_instance_identifier            = optional(string)
      source_db_instance_automated_backups_arn = optional(string)
      source_dbi_resource_id                   = optional(string)
      restore_time                             = optional(string)
      use_latest_restorable_time               = optional(bool, true)
    }))

    # Encryption
    storage_encrypted = optional(bool, true)
    kms_key_id        = optional(string)

    # Monitoring & Logging
    monitoring_interval    = optional(number, 0)
    monitoring_role_arn    = optional(string)
    create_monitoring_role = optional(bool, true)

    performance_insights_enabled          = optional(bool, false)
    performance_insights_kms_key_id       = optional(string)
    performance_insights_retention_period = optional(number, 7)

    enabled_cloudwatch_logs_exports        = optional(list(string), [])
    cloudwatch_log_group_retention_in_days = optional(number, 7)
    cloudwatch_log_group_kms_key_id        = optional(string)
    cloudwatch_log_class                   = optional(string, "STANDARD") # STANDARD or INFREQUENT_ACCESS

    # Parameter Group
    parameter_group = optional(object({
      name        = optional(string)
      family      = optional(string)
      description = optional(string, "DB parameter group for RDS instance")
      parameters = optional(list(object({
        name         = string
        value        = string
        apply_method = optional(string, "immediate")
      })), [])
    }))

    # Option Group (standard RDS only, not available in Aurora)
    option_group = optional(object({
      name                 = optional(string)
      engine_name          = optional(string)
      major_engine_version = optional(string)
      description          = optional(string, "DB option group for RDS instance")
      options = optional(list(object({
        option_name                    = string
        port                           = optional(number)
        version                        = optional(string)
        db_security_group_memberships  = optional(list(string))
        vpc_security_group_memberships = optional(list(string))
        option_settings = optional(list(object({
          name  = string
          value = string
        })), [])
      })), [])
    }))

    # Read Replica Configuration
    replicate_source_db = optional(string)

    # Blue/Green Deployment
    blue_green_update = optional(object({
      enabled = optional(bool, false)
    }))

    # CA Certificate
    ca_cert_identifier = optional(string)

    # Custom IAM Instance Profile
    custom_iam_instance_profile = optional(string)

    # Domain (Active Directory)
    domain                 = optional(string)
    domain_auth_secret_arn = optional(string)
    domain_dns_ips         = optional(list(string))
    domain_fqdn            = optional(string)
    domain_iam_role_name   = optional(string)
    domain_ou              = optional(string)

    # Character Sets (Oracle)
    character_set_name       = optional(string)
    nchar_character_set_name = optional(string)

    # Timeouts
    timeouts = optional(object({
      create = optional(string, "60m")
      update = optional(string, "80m")
      delete = optional(string, "60m")
    }), {})

    # Tags
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for inst_key, inst in var.instances :
      contains(["postgres", "mysql", "mariadb", "oracle-ee", "oracle-se2",
      "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web"], inst.engine)
    ])
    error_message = "engine debe ser uno de: postgres, mysql, mariadb, oracle-ee, oracle-se2, sqlserver-ee, sqlserver-se, sqlserver-ex, sqlserver-web."
  }

  validation {
    condition = alltrue([
      for inst_key, inst in var.instances :
      contains(["gp2", "gp3", "io1", "io2", "standard"], inst.storage_type)
    ])
    error_message = "storage_type debe ser uno de: gp2, gp3, io1, io2, standard."
  }

  validation {
    condition = alltrue([
      for inst_key, inst in var.instances :
      inst.backup_retention_period >= 0 && inst.backup_retention_period <= 35
    ])
    error_message = "backup_retention_period de la instancia debe estar entre 0 y 35 días."
  }

  validation {
    condition = alltrue([
      for inst_key, inst in var.instances :
      contains(["STANDARD", "INFREQUENT_ACCESS"], inst.cloudwatch_log_class)
    ])
    error_message = "cloudwatch_log_class debe ser 'STANDARD' o 'INFREQUENT_ACCESS'."
  }

  validation {
    condition = alltrue([
      for inst_key, inst in var.instances :
      !inst.manage_master_user_password_rotation_automatically || (
        inst.manage_master_user_password && inst.replicate_source_db == null && (
          inst.master_user_password_rotation_schedule_days != null ||
          inst.master_user_password_rotation_schedule_expression != null
        )
      )
    ])
    error_message = "La rotación automática requiere manage_master_user_password = true, no ser réplica y master_user_password_rotation_schedule_days o master_user_password_rotation_schedule_expression."
  }

  validation {
    condition = alltrue([
      for inst_key, inst in var.instances :
      inst.replicate_source_db == null || !startswith(coalesce(inst.replicate_source_db, "-"), "self:") || contains(keys(var.instances), trimprefix(coalesce(inst.replicate_source_db, "-"), "self:"))
    ])
    error_message = "replicate_source_db = \"self:<key>\" debe apuntar a una clave existente de instances."
  }
}

# =============================================================================
# Global Clusters Configuration
# =============================================================================

variable "global_clusters" {
  description = "Map of Aurora global cluster configurations (for multi-region disaster recovery)"
  type = map(object({
    global_cluster_identifier = string
    engine                    = optional(string) # aurora-mysql or aurora-postgresql
    engine_version            = optional(string)
    database_name             = optional(string)
    storage_encrypted         = optional(bool, true)
    deletion_protection       = optional(bool, true)

    # Engine lifecycle support
    engine_lifecycle_support = optional(string)

    # Force destroy on deletion
    force_destroy = optional(bool, false)

    # Source DB cluster (for creating global cluster from existing cluster)
    source_db_cluster_identifier = optional(string)

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for gc_key, gc in var.global_clusters :
      gc.engine != null ? contains(["aurora-mysql", "aurora-postgresql"], gc.engine) : true
    ])
    error_message = "El engine del global cluster debe ser 'aurora-mysql' o 'aurora-postgresql'."
  }
}

# =============================================================================
# RDS Proxy Configuration (Optional)
# =============================================================================

variable "db_proxies" {
  description = "Map of RDS Proxy configurations for connection pooling and management"
  type = map(object({
    cluster_key                  = optional(string) # Reference to cluster in var.clusters
    instance_key                 = optional(string) # Reference to instance in var.instances
    engine_family                = string           # MYSQL or POSTGRESQL
    require_tls                  = optional(bool, true)
    idle_client_timeout          = optional(number, 1800) # 0-28800 seconds
    max_connections_percent      = optional(number, 100)  # 1-100
    max_idle_connections_percent = optional(number, 50)   # 0-100
    connection_borrow_timeout    = optional(number, 120)  # 0-3600 seconds

    # Auth configuration
    auth = object({
      auth_scheme               = optional(string, "SECRETS")  # SECRETS or IAM
      secret_arn                = optional(string)             # Secrets Manager ARN
      iam_auth                  = optional(string, "DISABLED") # DISABLED or REQUIRED
      client_password_auth_type = optional(string)             # MYSQL_NATIVE_PASSWORD, POSTGRES_SCRAM_SHA_256, POSTGRES_MD5, SQL_SERVER_AUTHENTICATION
      description               = optional(string)
    })

    # Network configuration
    vpc_subnet_ids         = list(string)
    vpc_security_group_ids = optional(list(string), [])

    # Debugging
    debug_logging = optional(bool, false)

    # Session pinning filters
    session_pinning_filters = optional(list(string), [])

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for proxy_key, proxy in var.db_proxies :
      contains(["MYSQL", "POSTGRESQL"], proxy.engine_family)
    ])
    error_message = "engine_family del RDS Proxy debe ser 'MYSQL' o 'POSTGRESQL'."
  }

  validation {
    condition = alltrue([
      for proxy_key, proxy in var.db_proxies :
      proxy.max_connections_percent >= 1 && proxy.max_connections_percent <= 100
    ])
    error_message = "max_connections_percent del RDS Proxy debe estar entre 1 y 100."
  }

  validation {
    condition = alltrue([
      for proxy_key, proxy in var.db_proxies :
      (proxy.cluster_key != null) != (proxy.instance_key != null)
    ])
    error_message = "Cada RDS Proxy debe referenciar exactamente uno de cluster_key o instance_key, no ambos."
  }
}

# =============================================================================
# Blue/Green Deployment Configuration
# =============================================================================

variable "enable_blue_green_deployments" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. Enable blue/green deployment strategy for zero-downtime updates"
  type        = bool
  default     = false
}

variable "blue_green_update_timeout" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. Timeout for blue/green deployment updates (in minutes)"
  type        = number
  default     = 60

  validation {
    condition     = var.blue_green_update_timeout >= 15 && var.blue_green_update_timeout <= 720
    error_message = "blue_green_update_timeout debe estar entre 15 y 720 minutos."
  }
}

# =============================================================================
# Advanced Backup Configuration
# =============================================================================

variable "enable_cross_region_backups" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. Enable automated backups to another AWS region for disaster recovery"
  type        = bool
  default     = false
}

variable "cross_region_backup_config" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. Configuration for cross-region automated backups"
  type = object({
    destination_region = string
    kms_key_id         = optional(string)
    copy_tags          = optional(bool, true)
    pre_signed_url     = optional(string)
    source_region      = optional(string)
  })
  default = null
}

# =============================================================================
# Data API and Query Editor Configuration
# =============================================================================

variable "enable_query_editor" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. Enable RDS Query Editor for Serverless v2 clusters (requires Data API)"
  type        = bool
  default     = false
}

# =============================================================================
# Advanced Encryption Settings
# =============================================================================

variable "enable_encryption_in_transit" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. Enforce SSL/TLS for all connections (requires certificate validation)"
  type        = bool
  default     = true
}

variable "tls_cipher_suites" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. List of allowed TLS cipher suites for encrypted connections"
  type        = list(string)
  default     = []
}

# =============================================================================
# Cost Optimization Settings
# =============================================================================

variable "enable_cost_optimization" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. Enable cost optimization features (auto-pause for dev/test, Graviton instances, etc.)"
  type        = bool
  default     = false
}

variable "cost_optimization_config" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. Cost optimization configuration"
  type = object({
    prefer_graviton_instances          = optional(bool, true)  # Use Graviton2/3 instance types when available
    enable_storage_autoscaling         = optional(bool, false) # For Multi-AZ DB clusters
    storage_autoscaling_max_capacity   = optional(number)      # Maximum storage in GiB
    storage_autoscaling_target_percent = optional(number, 90)  # Target utilization percentage
  })
  default = null
}

# =============================================================================
# Compliance and Audit Settings
# =============================================================================

variable "enable_deletion_protection_override" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. Allow overriding deletion protection for emergency situations (not recommended for production)"
  type        = bool
  default     = false
}

variable "audit_log_retention_days" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. Retention period for audit logs in CloudWatch (if Activity Streams enabled)"
  type        = number
  default     = 90

  validation {
    condition     = var.audit_log_retention_days >= 1 && var.audit_log_retention_days <= 3653
    error_message = "audit_log_retention_days debe estar entre 1 y 3653 días."
  }
}

variable "enable_compliance_mode" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. Enable compliance mode with strict security settings (encryption, deletion protection, audit logs)"
  type        = bool
  default     = false
}

# =============================================================================
# Experimental Features
# =============================================================================

variable "enable_experimental_features" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. Enable experimental/preview features (use with caution in production)"
  type        = bool
  default     = false
}

variable "experimental_config" {
  description = "DEPRECATED: not used by the module, kept for backward compatibility and ignored. Configuration for experimental features"
  type = object({
    enable_aurora_ml          = optional(bool, false) # Aurora ML for SageMaker/Comprehend integration
    enable_rds_custom         = optional(bool, false) # RDS Custom for OS/DB customization
    enable_multi_master       = optional(bool, false) # Multi-master (deprecated, use Limitless instead)
    enable_performance_schema = optional(bool, false) # MySQL Performance Schema
    enable_query_insights     = optional(bool, false) # Advanced query performance insights
  })
  default = null
}
