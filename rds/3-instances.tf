# =============================================================================
# Aurora Cluster Instances
# =============================================================================

resource "aws_rds_cluster_instance" "this" {
  for_each = var.create ? local.cluster_instances : {}

  identifier         = each.value.identifier
  cluster_identifier = aws_rds_cluster.this[each.value.cluster_key].id

  # Instance Configuration
  instance_class = each.value.instance_class
  engine         = each.value.cluster.engine
  engine_version = each.value.cluster.engine_version

  # Network
  publicly_accessible = each.value.publicly_accessible
  availability_zone   = each.value.availability_zone
  # Note: network_type is auto-configured based on cluster configuration

  # Promotion
  promotion_tier = each.value.promotion_tier

  # Maintenance
  preferred_maintenance_window = each.value.preferred_maintenance_window
  auto_minor_version_upgrade   = each.value.auto_minor_version_upgrade
  apply_immediately            = each.value.cluster.apply_immediately

  # CA Certificate
  ca_cert_identifier = each.value.ca_cert_identifier

  # Enhanced Monitoring
  monitoring_interval = each.value.monitoring_interval
  monitoring_role_arn = each.value.monitoring_interval > 0 ? (
    each.value.monitoring_role_arn != null ? each.value.monitoring_role_arn : (
      each.value.cluster.create_monitoring_role ? try(aws_iam_role.monitoring[each.value.cluster_key].arn, null) : null
    )
  ) : null

  # Performance Insights
  performance_insights_enabled          = each.value.performance_insights_enabled
  performance_insights_kms_key_id       = each.value.performance_insights_kms_key_id
  performance_insights_retention_period = each.value.performance_insights_enabled ? each.value.performance_insights_retention_period : null

  # Note: Performance Insights retention period determines the insights mode:
  # - 7 days = standard mode (free)
  # - Up to 731 days = advanced mode (paid)

  # Parameter Group
  db_parameter_group_name = each.value.cluster.db_parameter_group != null ? aws_db_parameter_group.this[each.value.cluster_key].name : null

  # Copy tags from cluster
  copy_tags_to_snapshot = each.value.copy_tags_to_snapshot

  # Custom IAM instance profile
  custom_iam_instance_profile = each.value.custom_iam_instance_profile

  # Tags
  tags = merge(
    local.cluster_tags[each.value.cluster_key],
    each.value.tags,
    {
      Name = each.value.identifier
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
