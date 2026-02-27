# =============================================================================
# Cluster Parameter Groups
# =============================================================================

resource "aws_rds_cluster_parameter_group" "this" {
  for_each = var.create ? local.cluster_parameter_groups : {}

  name        = coalesce(each.value.name, "${local.name_prefix}cluster-pg-${var.account_name}-${var.project_name}-${each.key}")
  family      = each.value.family
  description = each.value.description

  dynamic "parameter" {
    for_each = each.value.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(
    var.tags_common,
    {
      Name = coalesce(each.value.name, "${local.name_prefix}cluster-pg-${var.account_name}-${var.project_name}-${each.key}")
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# DB Parameter Groups (for Aurora cluster instances)
# =============================================================================

resource "aws_db_parameter_group" "this" {
  for_each = var.create ? local.db_parameter_groups : {}

  name        = coalesce(each.value.name, "${local.name_prefix}db-pg-${var.account_name}-${var.project_name}-${each.key}")
  family      = each.value.family
  description = each.value.description

  dynamic "parameter" {
    for_each = each.value.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(
    var.tags_common,
    {
      Name = coalesce(each.value.name, "${local.name_prefix}db-pg-${var.account_name}-${var.project_name}-${each.key}")
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# DB Parameter Groups (for standalone RDS instances)
# =============================================================================

resource "aws_db_parameter_group" "instances" {
  for_each = var.create ? local.instance_parameter_groups : {}

  name        = coalesce(each.value.name, "${local.name_prefix}db-pg-inst-${var.account_name}-${var.project_name}-${each.key}")
  family      = each.value.family
  description = each.value.description

  dynamic "parameter" {
    for_each = each.value.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(
    var.tags_common,
    {
      Name = coalesce(each.value.name, "${local.name_prefix}db-pg-inst-${var.account_name}-${var.project_name}-${each.key}")
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
