# =============================================================================
# CloudWatch Log Groups
# =============================================================================

resource "aws_cloudwatch_log_group" "this" {
  for_each = var.create ? local.cloudwatch_log_groups_enhanced : {}

  name              = each.value.name
  retention_in_days = each.value.retention_in_days
  kms_key_id        = each.value.kms_key_id
  # Note: log_class (STANDARD/INFREQUENT_ACCESS) is configured via CloudWatch Logs console or API
  # It's not a Terraform aws_cloudwatch_log_group attribute

  tags = merge(
    var.tags_common,
    {
      Name     = each.value.name
      LogType  = each.value.log_type
      Cluster  = each.value.cluster_key
      LogClass = each.value.log_class # Tag for reference
    }
  )
}

# =============================================================================
# IAM Role for Enhanced Monitoring
# =============================================================================

resource "aws_iam_role" "monitoring" {
  for_each = var.create ? local.monitoring_roles_to_create : {}

  name = "${local.name_prefix}role-rds-monitoring-${var.account_name}-${var.project_name}-${each.key}"

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
      Name = "${local.name_prefix}role-rds-monitoring-${var.account_name}-${var.project_name}-${each.key}"
    }
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

  tags = merge(
    var.tags_common,
    {
      Name     = each.value.name
      LogType  = each.value.log_type
      Instance = each.value.instance_key
    }
  )
}

# =============================================================================
# IAM Role for Enhanced Monitoring (Standard Instances)
# =============================================================================

resource "aws_iam_role" "instance_monitoring" {
  for_each = var.create ? local.instance_monitoring_roles_to_create : {}

  name = "${local.name_prefix}role-rds-mon-inst-${var.account_name}-${var.project_name}-${each.key}"

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
      Name = "${local.name_prefix}role-rds-mon-inst-${var.account_name}-${var.project_name}-${each.key}"
    }
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
