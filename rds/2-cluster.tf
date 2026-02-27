# =============================================================================
# DB Subnet Groups
# =============================================================================

resource "aws_db_subnet_group" "this" {
  for_each = var.create ? local.subnet_groups_to_create : {}

  name        = "${local.name_prefix}subnet-group-${var.account_name}-${var.project_name}-${each.key}"
  description = "Subnet group for Aurora cluster ${each.key}"
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
# Global Clusters (Multi-Region Disaster Recovery)
# =============================================================================

resource "aws_rds_global_cluster" "this" {
  for_each = var.create ? var.global_clusters : {}

  global_cluster_identifier    = each.value.global_cluster_identifier
  engine                       = each.value.engine
  engine_version               = each.value.engine_version
  database_name                = each.value.database_name
  storage_encrypted            = each.value.storage_encrypted
  deletion_protection          = each.value.deletion_protection
  engine_lifecycle_support     = each.value.engine_lifecycle_support
  force_destroy                = each.value.force_destroy
  source_db_cluster_identifier = each.value.source_db_cluster_identifier

  lifecycle {
    ignore_changes = [
      engine_version
    ]
  }
}

# =============================================================================
# Aurora Clusters
# =============================================================================

resource "aws_rds_cluster" "this" {
  for_each = var.create ? var.clusters : {}

  cluster_identifier_prefix = each.value.cluster_identifier_prefix
  cluster_identifier        = each.value.cluster_identifier_prefix == null ? "${local.name_prefix}cluster-${var.account_name}-${var.project_name}-${each.key}" : null

  # Engine Configuration
  engine                    = each.value.engine
  engine_version            = each.value.engine_version
  engine_mode               = each.value.engine_mode
  engine_lifecycle_support  = each.value.engine_lifecycle_support
  cluster_scalability_type  = each.value.cluster_scalability_type
  ca_certificate_identifier = each.value.cluster_ca_cert_identifier

  # Database
  database_name   = each.value.database_name
  master_username = each.value.master_username
  master_password = !each.value.manage_master_user_password ? each.value.master_password : null
  port            = local.cluster_ports[each.key]

  # Managed Password via AWS Secrets Manager
  manage_master_user_password   = each.value.manage_master_user_password
  master_user_secret_kms_key_id = each.value.master_user_secret_kms_key_id

  # Note: Password rotation is configured separately via aws_secretsmanager_secret_rotation
  # when manage_master_user_password is enabled. RDS cluster resource doesn't expose
  # rotation schedule parameters directly.

  # IAM Authentication
  iam_database_authentication_enabled = each.value.iam_database_authentication_enabled

  # Network (security group IDs passed directly - no module creation)
  vpc_security_group_ids = each.value.vpc_security_group_ids
  db_subnet_group_name   = each.value.create_subnet_group ? aws_db_subnet_group.this[each.key].name : each.value.db_subnet_group_name
  network_type           = each.value.network_type
  availability_zones     = length(each.value.availability_zones) > 0 ? each.value.availability_zones : null

  # Backup
  backup_retention_period      = each.value.backup_retention_period
  preferred_backup_window      = each.value.preferred_backup_window
  preferred_maintenance_window = each.value.preferred_maintenance_window
  skip_final_snapshot          = each.value.skip_final_snapshot
  final_snapshot_identifier    = local.final_snapshot_identifiers[each.key]
  snapshot_identifier          = each.value.snapshot_identifier
  copy_tags_to_snapshot        = each.value.copy_tags_to_snapshot
  backtrack_window             = each.value.backtrack_window

  # Point-in-time Restore
  dynamic "restore_to_point_in_time" {
    for_each = each.value.restore_to_point_in_time != null ? [each.value.restore_to_point_in_time] : []
    content {
      source_cluster_identifier  = restore_to_point_in_time.value.source_cluster_identifier
      restore_type               = restore_to_point_in_time.value.restore_type
      use_latest_restorable_time = restore_to_point_in_time.value.use_latest_restorable_time
      restore_to_time            = restore_to_point_in_time.value.restore_to_time
    }
  }

  # S3 Import (MySQL only)
  dynamic "s3_import" {
    for_each = each.value.s3_import != null ? [each.value.s3_import] : []
    content {
      source_engine         = s3_import.value.source_engine
      source_engine_version = s3_import.value.source_engine_version
      bucket_name           = s3_import.value.bucket_name
      bucket_prefix         = s3_import.value.bucket_prefix
      ingestion_role        = s3_import.value.ingestion_role
    }
  }

  # Encryption
  storage_encrypted = each.value.storage_encrypted
  kms_key_id        = each.value.kms_key_id

  # Deletion Protection
  deletion_protection = each.value.deletion_protection
  apply_immediately   = each.value.apply_immediately

  # CloudWatch Logs (log_class configured in log group resource)
  enabled_cloudwatch_logs_exports = each.value.enabled_cloudwatch_logs_exports

  # Serverless v1 Configuration
  dynamic "scaling_configuration" {
    for_each = each.value.scaling_configuration != null ? [each.value.scaling_configuration] : []
    content {
      auto_pause               = scaling_configuration.value.auto_pause
      max_capacity             = scaling_configuration.value.max_capacity
      min_capacity             = scaling_configuration.value.min_capacity
      seconds_until_auto_pause = scaling_configuration.value.seconds_until_auto_pause
      timeout_action           = scaling_configuration.value.timeout_action
    }
  }

  # Serverless v2 Configuration
  dynamic "serverlessv2_scaling_configuration" {
    for_each = each.value.serverlessv2_scaling_configuration != null ? [each.value.serverlessv2_scaling_configuration] : []
    content {
      max_capacity = serverlessv2_scaling_configuration.value.max_capacity
      min_capacity = serverlessv2_scaling_configuration.value.min_capacity
    }
  }

  # Global Database
  global_cluster_identifier      = each.value.global_cluster_identifier
  enable_global_write_forwarding = each.value.enable_global_write_forwarding
  enable_local_write_forwarding  = each.value.enable_local_write_forwarding

  # HTTP Endpoint (Data API for Serverless)
  enable_http_endpoint = each.value.enable_http_endpoint

  # Parameter Groups
  db_cluster_parameter_group_name = each.value.cluster_parameter_group != null ? aws_rds_cluster_parameter_group.this[each.key].name : null

  # Domain (Active Directory Integration)
  domain               = each.value.domain
  domain_iam_role_name = each.value.domain_iam_role_name

  # Allocated Storage (for Multi-AZ DB clusters)
  allocated_storage = each.value.allocated_storage
  storage_type      = each.value.storage_type
  iops              = each.value.iops

  # Replication
  replication_source_identifier = each.value.replication_source_identifier
  source_region                 = each.value.source_region

  # Version Upgrade
  allow_major_version_upgrade = each.value.allow_major_version_upgrade

  # Tags
  tags = local.cluster_tags[each.key]

  # Timeouts
  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  # Dependencies
  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role.monitoring,
    aws_rds_global_cluster.this
  ]

  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      availability_zones,
      snapshot_identifier,
      cluster_scalability_type
    ]
  }
}

# =============================================================================
# Aurora Limitless Database - Shard Groups
# =============================================================================

# Note: Aurora Limitless Database Shard Groups are configured automatically by AWS
# when cluster_scalability_type = "limitless" is set on the cluster.
# There is no separate aws_rds_shard_group resource in the current AWS provider.
# The shard_group configuration is part of the cluster resource configuration.

# =============================================================================
# Custom Endpoints
# =============================================================================

resource "aws_rds_cluster_endpoint" "this" {
  for_each = var.create ? local.custom_endpoints : {}

  cluster_identifier          = aws_rds_cluster.this[each.value.cluster_key].id
  cluster_endpoint_identifier = each.value.identifier
  custom_endpoint_type        = each.value.type

  static_members   = length(each.value.static_members) > 0 ? each.value.static_members : null
  excluded_members = length(each.value.excluded_members) > 0 ? each.value.excluded_members : null

  tags = merge(
    var.tags_common,
    each.value.tags,
    {
      Name = each.value.identifier
    }
  )

  depends_on = [
    aws_rds_cluster_instance.this
  ]
}

# =============================================================================
# IAM Role Associations
# =============================================================================

resource "aws_rds_cluster_role_association" "this" {
  for_each = var.create ? local.iam_role_associations : {}

  db_cluster_identifier = aws_rds_cluster.this[each.value.cluster_key].id
  role_arn              = each.value.role_arn
  feature_name          = each.value.feature_name
}
