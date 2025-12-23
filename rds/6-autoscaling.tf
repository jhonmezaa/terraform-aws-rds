# =============================================================================
# Autoscaling Target
# =============================================================================

resource "aws_appautoscaling_target" "this" {
  for_each = var.create ? local.autoscaling_clusters : {}

  max_capacity       = each.value.autoscaling.max_capacity
  min_capacity       = each.value.autoscaling.min_capacity
  resource_id        = "cluster:${aws_rds_cluster.this[each.key].cluster_identifier}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"

  tags = merge(
    var.tags_common,
    local.cluster_tags[each.key],
    {
      Name = "${local.region_prefix}-autoscaling-target-${var.account_name}-${var.project_name}-${each.key}"
    }
  )
}

# =============================================================================
# Target Tracking Scaling Policies
# =============================================================================

resource "aws_appautoscaling_policy" "target_tracking" {
  for_each = var.create ? local.autoscaling_target_tracking_policies : {}

  name               = "${local.region_prefix}-autoscaling-target-${var.account_name}-${var.project_name}-${each.value.cluster_key}-${each.value.policy_key}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[each.value.cluster_key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.value.cluster_key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[each.value.cluster_key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = each.value.target_metric
    }

    target_value       = each.value.target_value
    scale_in_cooldown  = each.value.scale_in_cooldown
    scale_out_cooldown = each.value.scale_out_cooldown
    disable_scale_in   = each.value.disable_scale_in
  }
}

# =============================================================================
# Step Scaling Policies
# =============================================================================

resource "aws_appautoscaling_policy" "step_scaling" {
  for_each = var.create ? local.autoscaling_step_scaling_policies : {}

  name               = "${local.region_prefix}-autoscaling-step-${var.account_name}-${var.project_name}-${each.value.cluster_key}-${each.value.policy_key}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.this[each.value.cluster_key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.value.cluster_key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[each.value.cluster_key].service_namespace

  step_scaling_policy_configuration {
    adjustment_type          = each.value.adjustment_type
    metric_aggregation_type  = each.value.metric_aggregation_type
    cooldown                 = each.value.cooldown
    min_adjustment_magnitude = each.value.min_adjustment_magnitude

    dynamic "step_adjustment" {
      for_each = each.value.step_adjustments
      content {
        scaling_adjustment          = step_adjustment.value.scaling_adjustment
        metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
        metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
      }
    }
  }
}

# =============================================================================
# CloudWatch Alarms for Step Scaling
# =============================================================================

resource "aws_cloudwatch_metric_alarm" "step_scaling" {
  for_each = var.create ? local.autoscaling_step_scaling_policies : {}

  alarm_name          = "${local.region_prefix}-alarm-autoscaling-${var.account_name}-${var.project_name}-${each.value.cluster_key}-${each.value.policy_key}"
  comparison_operator = each.value.alarm.comparison_operator
  evaluation_periods  = each.value.alarm.evaluation_periods
  metric_name         = each.value.alarm.metric_name
  namespace           = each.value.alarm.namespace
  period              = each.value.alarm.period
  statistic           = each.value.alarm.statistic
  threshold           = each.value.alarm.threshold

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.this[each.value.cluster_key].cluster_identifier
  }

  alarm_actions = [
    aws_appautoscaling_policy.step_scaling[each.key].arn
  ]

  tags = merge(
    var.tags_common,
    local.cluster_tags[each.value.cluster_key],
    {
      Name    = "${local.region_prefix}-alarm-autoscaling-${var.account_name}-${var.project_name}-${each.value.cluster_key}-${each.value.policy_key}"
      Cluster = each.value.cluster_key
      Policy  = each.value.policy_key
    }
  )
}

# =============================================================================
# Scheduled Actions
# =============================================================================

resource "aws_appautoscaling_scheduled_action" "this" {
  for_each = var.create ? local.autoscaling_scheduled_actions : {}

  name               = "${local.region_prefix}-autoscaling-schedule-${var.account_name}-${var.project_name}-${each.value.cluster_key}-${each.value.action_key}"
  service_namespace  = aws_appautoscaling_target.this[each.value.cluster_key].service_namespace
  resource_id        = aws_appautoscaling_target.this[each.value.cluster_key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.value.cluster_key].scalable_dimension
  schedule           = each.value.schedule
  timezone           = each.value.timezone

  scalable_target_action {
    min_capacity = each.value.min_capacity
    max_capacity = each.value.max_capacity
  }

  start_time = each.value.start_time
  end_time   = each.value.end_time
}
