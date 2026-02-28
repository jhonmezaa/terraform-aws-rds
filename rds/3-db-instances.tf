# =============================================================================
# Standard RDS DB Instances (Primary)
# =============================================================================

resource "aws_db_instance" "this" {
  for_each = var.create ? local.db_instance_primary_configs : {}

  identifier = each.value.identifier

  # Engine
  engine         = each.value.engine
  engine_version = each.value.engine_version
  license_model  = each.value.license_model

  # Instance
  instance_class = each.value.instance_class

  # Storage
  allocated_storage     = each.value.is_read_replica ? null : each.value.allocated_storage
  max_allocated_storage = each.value.max_allocated_storage
  storage_type          = each.value.storage_type
  iops                  = each.value.iops
  storage_throughput    = each.value.storage_throughput

  # Database
  db_name = each.value.is_read_replica ? null : each.value.database_name
  port    = each.value.port

  # Credentials (skip for read replicas)
  username                      = each.value.is_read_replica ? null : each.value.master_username
  password                      = each.value.is_read_replica ? null : (!each.value.manage_master_user_password ? each.value.master_password : null)
  manage_master_user_password   = each.value.is_read_replica ? null : (each.value.manage_master_user_password ? true : null)
  master_user_secret_kms_key_id = each.value.is_read_replica ? null : (each.value.manage_master_user_password ? each.value.master_user_secret_kms_key_id : null)

  iam_database_authentication_enabled = each.value.iam_database_authentication_enabled

  # Network
  vpc_security_group_ids = each.value.vpc_security_group_ids
  db_subnet_group_name = each.value.is_read_replica ? null : (
    each.value.create_subnet_group && length(each.value.subnet_ids) > 0 ? aws_db_subnet_group.instances[each.key].name : each.value.db_subnet_group_name
  )
  network_type        = each.value.network_type
  publicly_accessible = each.value.publicly_accessible
  availability_zone   = each.value.availability_zone
  multi_az            = each.value.multi_az

  # Backup
  backup_retention_period = each.value.backup_retention_period
  backup_window           = each.value.backup_window
  maintenance_window      = each.value.maintenance_window

  # Version Upgrades
  auto_minor_version_upgrade  = each.value.auto_minor_version_upgrade
  allow_major_version_upgrade = each.value.allow_major_version_upgrade
  apply_immediately           = each.value.apply_immediately

  # Deletion & Snapshots
  deletion_protection       = each.value.deletion_protection
  skip_final_snapshot       = each.value.skip_final_snapshot
  final_snapshot_identifier = each.value.final_snapshot_id
  delete_automated_backups  = each.value.delete_automated_backups
  copy_tags_to_snapshot     = each.value.copy_tags_to_snapshot

  # Snapshot Restore
  snapshot_identifier = each.value.snapshot_identifier

  # Point-in-time Restore
  dynamic "restore_to_point_in_time" {
    for_each = each.value.restore_to_point_in_time != null ? [each.value.restore_to_point_in_time] : []
    content {
      source_db_instance_identifier            = restore_to_point_in_time.value.source_db_instance_identifier
      source_db_instance_automated_backups_arn = restore_to_point_in_time.value.source_db_instance_automated_backups_arn
      source_dbi_resource_id                   = restore_to_point_in_time.value.source_dbi_resource_id
      restore_time                             = restore_to_point_in_time.value.restore_time
      use_latest_restorable_time               = restore_to_point_in_time.value.use_latest_restorable_time
    }
  }

  # Encryption
  storage_encrypted = each.value.storage_encrypted
  kms_key_id        = each.value.kms_key_id

  # Monitoring
  monitoring_interval = each.value.monitoring_interval
  monitoring_role_arn = each.value.monitoring_interval > 0 ? coalesce(
    each.value.monitoring_role_arn,
    each.value.create_monitoring_role ? try(aws_iam_role.instance_monitoring[each.key].arn, null) : null
  ) : null

  # Performance Insights
  performance_insights_enabled          = each.value.performance_insights_enabled
  performance_insights_kms_key_id       = each.value.performance_insights_enabled ? each.value.performance_insights_kms_key_id : null
  performance_insights_retention_period = each.value.performance_insights_enabled ? each.value.performance_insights_retention_period : null

  # CloudWatch Logs
  enabled_cloudwatch_logs_exports = each.value.enabled_cloudwatch_logs_exports

  # Parameter Group
  parameter_group_name = each.value.parameter_group != null ? aws_db_parameter_group.instances[each.key].name : null

  # Option Group
  option_group_name = each.value.option_group != null ? aws_db_option_group.this[each.key].name : null

  # Read Replica (external only for primary configs)
  replicate_source_db = each.value.is_read_replica ? each.value.replicate_source_db : null

  # Blue/Green Deployment
  dynamic "blue_green_update" {
    for_each = each.value.blue_green_update != null ? [each.value.blue_green_update] : []
    content {
      enabled = blue_green_update.value.enabled
    }
  }

  # CA Certificate
  ca_cert_identifier = each.value.ca_cert_identifier

  # Custom IAM Instance Profile
  custom_iam_instance_profile = each.value.custom_iam_instance_profile

  # Domain (Active Directory)
  domain                 = each.value.domain
  domain_auth_secret_arn = each.value.domain_auth_secret_arn
  domain_dns_ips         = each.value.domain_dns_ips
  domain_fqdn            = each.value.domain_fqdn
  domain_iam_role_name   = each.value.domain_iam_role_name
  domain_ou              = each.value.domain_ou

  # Character Sets (Oracle)
  character_set_name       = each.value.character_set_name
  nchar_character_set_name = each.value.nchar_character_set_name

  tags = each.value.merged_tags

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.instances,
    aws_iam_role.instance_monitoring
  ]

  lifecycle {
    ignore_changes = [
      snapshot_identifier
    ]
  }
}

# =============================================================================
# Standard RDS DB Instances (Self-Referencing Read Replicas)
# =============================================================================

resource "aws_db_instance" "read_replica" {
  for_each = var.create ? local.db_instance_replica_configs : {}

  identifier = each.value.identifier

  # Engine (inherited from source, but required by Terraform)
  instance_class = each.value.instance_class

  # Storage
  max_allocated_storage = each.value.max_allocated_storage
  storage_type          = each.value.storage_type
  iops                  = each.value.iops
  storage_throughput    = each.value.storage_throughput

  # Read Replica Source
  replicate_source_db = aws_db_instance.this[each.value.source_instance_key].identifier

  # Network
  vpc_security_group_ids = each.value.vpc_security_group_ids
  network_type           = each.value.network_type
  publicly_accessible    = each.value.publicly_accessible
  availability_zone      = each.value.availability_zone
  multi_az               = each.value.multi_az
  port                   = each.value.port

  # Maintenance
  auto_minor_version_upgrade  = each.value.auto_minor_version_upgrade
  allow_major_version_upgrade = each.value.allow_major_version_upgrade
  apply_immediately           = each.value.apply_immediately
  maintenance_window          = each.value.maintenance_window

  # Deletion
  deletion_protection      = each.value.deletion_protection
  skip_final_snapshot      = each.value.skip_final_snapshot
  delete_automated_backups = each.value.delete_automated_backups
  copy_tags_to_snapshot    = each.value.copy_tags_to_snapshot

  # Encryption
  storage_encrypted = each.value.storage_encrypted
  kms_key_id        = each.value.kms_key_id

  # Monitoring
  monitoring_interval = each.value.monitoring_interval
  monitoring_role_arn = each.value.monitoring_interval > 0 ? coalesce(
    each.value.monitoring_role_arn,
    each.value.create_monitoring_role ? try(aws_iam_role.instance_monitoring[each.key].arn, null) : null
  ) : null

  # Performance Insights
  performance_insights_enabled          = each.value.performance_insights_enabled
  performance_insights_kms_key_id       = each.value.performance_insights_enabled ? each.value.performance_insights_kms_key_id : null
  performance_insights_retention_period = each.value.performance_insights_enabled ? each.value.performance_insights_retention_period : null

  # CloudWatch Logs
  enabled_cloudwatch_logs_exports = each.value.enabled_cloudwatch_logs_exports

  # Parameter Group
  parameter_group_name = each.value.parameter_group != null ? aws_db_parameter_group.instances[each.key].name : null

  # Option Group
  option_group_name = each.value.option_group != null ? aws_db_option_group.this[each.key].name : null

  # CA Certificate
  ca_cert_identifier = each.value.ca_cert_identifier

  tags = each.value.merged_tags

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.instances,
    aws_iam_role.instance_monitoring
  ]

  lifecycle {
    ignore_changes = [
      snapshot_identifier
    ]
  }
}

# =============================================================================
# DB Subnet Groups for Standard Instances
# =============================================================================

resource "aws_db_subnet_group" "instances" {
  for_each = var.create ? local.instance_subnet_groups_to_create : {}

  name        = "${local.name_prefix}subnet-group-${var.account_name}-${var.project_name}-${each.key}"
  description = "Subnet group for RDS instance ${each.key}"
  subnet_ids  = each.value.subnet_ids

  tags = merge(
    var.tags_common,
    each.value.tags,
    {
      Name = "${local.name_prefix}subnet-group-${var.account_name}-${var.project_name}-${each.key}"
    }
  )
}

# =============================================================================
# DB Option Groups (Standard RDS only)
# =============================================================================

resource "aws_db_option_group" "this" {
  for_each = var.create ? local.instance_option_groups : {}

  name                     = coalesce(each.value.name, "${local.name_prefix}option-group-${var.account_name}-${var.project_name}-${each.key}")
  engine_name              = each.value.engine_name
  major_engine_version     = each.value.major_engine_version
  option_group_description = each.value.description

  dynamic "option" {
    for_each = each.value.options
    content {
      option_name                    = option.value.option_name
      port                           = option.value.port
      version                        = option.value.version
      db_security_group_memberships  = option.value.db_security_group_memberships
      vpc_security_group_memberships = option.value.vpc_security_group_memberships

      dynamic "option_settings" {
        for_each = option.value.option_settings
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(
    var.tags_common,
    {
      Name = coalesce(each.value.name, "${local.name_prefix}option-group-${var.account_name}-${var.project_name}-${each.key}")
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
