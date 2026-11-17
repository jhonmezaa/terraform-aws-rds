# =============================================================================
# CloudWatch Log Groups
# =============================================================================

resource "aws_cloudwatch_log_group" "this" {
  for_each = var.create ? local.cloudwatch_log_groups_enhanced : {}

  name              = each.value.name
  retention_in_days = each.value.retention_in_days
  kms_key_id        = each.value.kms_key_id
  log_group_class   = each.value.log_class

  tags = merge(
    var.tags_common,
    {
      Name     = each.value.name
      LogType  = each.value.log_type
      Cluster  = each.value.cluster_key
      LogClass = each.value.log_class # Tag for reference
    },
    local.managed_by_tags
  )
}

# =============================================================================
# IAM Role for Enhanced Monitoring
# =============================================================================

resource "aws_iam_role" "monitoring" {
  for_each = var.create ? local.monitoring_roles_to_create : {}

  name = local.monitoring_role_names[each.key]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags_common,
    {
      Name = local.monitoring_role_names[each.key]
    },
    local.managed_by_tags
  )
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  for_each = var.create ? local.monitoring_roles_to_create : {}

  role       = aws_iam_role.monitoring[each.key].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# =============================================================================
# CloudWatch Log Groups for Standard RDS Instances
# =============================================================================

resource "aws_cloudwatch_log_group" "instances" {
  for_each = var.create ? local.instance_cloudwatch_log_groups : {}

  name              = each.value.name
  retention_in_days = each.value.retention_in_days
  kms_key_id        = each.value.kms_key_id
  log_group_class   = each.value.log_class

  tags = merge(
    var.tags_common,
    {
      Name     = each.value.name
      LogType  = each.value.log_type
      Instance = each.value.instance_key
    },
    local.managed_by_tags
  )
}

# =============================================================================
# IAM Role for Enhanced Monitoring (Standard Instances)
# =============================================================================

resource "aws_iam_role" "instance_monitoring" {
  for_each = var.create ? local.instance_monitoring_roles_to_create : {}

  name = local.instance_monitoring_role_names[each.key]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags_common,
    {
      Name = local.instance_monitoring_role_names[each.key]
    },
    local.managed_by_tags
  )
}

resource "aws_iam_role_policy_attachment" "instance_monitoring" {
  for_each = var.create ? local.instance_monitoring_roles_to_create : {}

  role       = aws_iam_role.instance_monitoring[each.key].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# =============================================================================
# Activity Streams
# =============================================================================

resource "aws_rds_cluster_activity_stream" "this" {
  for_each = var.create ? local.activity_streams : {}

  resource_arn = aws_rds_cluster.this[each.key].arn
  mode         = each.value.mode
  kms_key_id   = each.value.kms_key_id

  engine_native_audit_fields_included = each.value.engine_native_audit_fields_included

  depends_on = [
    aws_rds_cluster_instance.this
  ]
}

# =============================================================================
# Managed Master Password Rotation (Secrets Manager)
# =============================================================================
# Only for secrets managed by RDS (manage_master_user_password = true).
# AWS rotates RDS-managed secrets without a Lambda function; only the schedule
# is configured here.

resource "aws_secretsmanager_secret_rotation" "clusters" {
  for_each = var.create ? local.cluster_secret_rotations : {}

  secret_id          = aws_rds_cluster.this[each.key].master_user_secret[0].secret_arn
  rotate_immediately = each.value.master_user_password_rotate_immediately

  rotation_rules {
    automatically_after_days = each.value.master_user_password_rotation_schedule_days
    schedule_expression      = each.value.master_user_password_rotation_schedule_expression
    duration                 = each.value.master_user_password_rotation_duration
  }
}

resource "aws_secretsmanager_secret_rotation" "instances" {
  for_each = var.create ? local.instance_secret_rotations : {}

  secret_id          = aws_db_instance.this[each.key].master_user_secret[0].secret_arn
  rotate_immediately = each.value.master_user_password_rotate_immediately

  rotation_rules {
    automatically_after_days = each.value.master_user_password_rotation_schedule_days
    schedule_expression      = each.value.master_user_password_rotation_schedule_expression
    duration                 = each.value.master_user_password_rotation_duration
  }
}
