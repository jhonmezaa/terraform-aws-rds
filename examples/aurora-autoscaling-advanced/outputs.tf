# =============================================================================
# Cluster Outputs
# =============================================================================

output "cluster_id" {
  description = "Aurora cluster identifier"
  value       = module.aurora_autoscaling.cluster_ids["autoscaling"]
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = module.aurora_autoscaling.cluster_arns["autoscaling"]
}

output "cluster_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = module.aurora_autoscaling.cluster_endpoints["autoscaling"]
}

output "cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint (load balanced across replicas)"
  value       = module.aurora_autoscaling.cluster_reader_endpoints["autoscaling"]
}

output "cluster_port" {
  description = "Aurora cluster port"
  value       = module.aurora_autoscaling.cluster_ports["autoscaling"]
}

# =============================================================================
# Secrets Manager Outputs
# =============================================================================

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing master user credentials"
  value       = module.aurora_autoscaling.cluster_master_user_secret_arns["autoscaling"]
  sensitive   = true
}

# =============================================================================
# Instance Outputs
# =============================================================================

output "instance_ids" {
  description = "Map of instance identifiers"
  value       = module.aurora_autoscaling.cluster_instance_ids
}

output "instance_endpoints" {
  description = "Map of instance endpoints"
  value       = module.aurora_autoscaling.cluster_instance_endpoints
}

# =============================================================================
# Autoscaling Outputs
# =============================================================================

output "autoscaling_target_id" {
  description = "Autoscaling target resource ID"
  value       = module.aurora_autoscaling.autoscaling_target_ids["autoscaling"]
}

output "autoscaling_target_tracking_policies" {
  description = "Map of target tracking policy ARNs"
  value       = module.aurora_autoscaling.autoscaling_target_tracking_policy_arns
}

output "autoscaling_step_scaling_policies" {
  description = "Map of step scaling policy ARNs"
  value       = module.aurora_autoscaling.autoscaling_step_scaling_policy_arns
}

output "autoscaling_scheduled_actions" {
  description = "Map of scheduled action names"
  value       = module.aurora_autoscaling.autoscaling_scheduled_action_names
}

# =============================================================================
# Usage Instructions
# =============================================================================

output "connection_info" {
  description = "Connection information and autoscaling details"
  value       = <<-EOT

  ==========================================
  Aurora Cluster with Advanced Autoscaling
  ==========================================

  Cluster Endpoint: ${module.aurora_autoscaling.cluster_endpoints["autoscaling"]}
  Reader Endpoint:  ${module.aurora_autoscaling.cluster_reader_endpoints["autoscaling"]}
  Port: ${module.aurora_autoscaling.cluster_ports["autoscaling"]}
  Database: ${var.database_name}

  HOW TO CONNECT:
  --------------------

  1. Retrieve the master password from Secrets Manager:

     aws secretsmanager get-secret-value \
       --secret-id ${module.aurora_autoscaling.cluster_master_user_secret_arns["autoscaling"]} \
       --query SecretString --output text | jq -r .password

  2. Connect using psql:

     psql -h ${module.aurora_autoscaling.cluster_endpoints["autoscaling"]} \
          -p ${module.aurora_autoscaling.cluster_ports["autoscaling"]} \
          -U ${var.db_username} \
          -d ${var.database_name}

  AUTOSCALING CONFIGURATION:
  --------------------
  Min Capacity: ${var.min_capacity} replicas
  Max Capacity: ${var.max_capacity} replicas

  Target Tracking Policies:
  - CPU: Target ${var.cpu_target_value}% utilization
  - Connections: Target ${var.connections_target_value} connections

  Scheduled Actions:
  - Business Hours (${var.business_hours_start}): ${var.business_hours_min_capacity}-${var.business_hours_max_capacity} replicas
  - Off Hours (${var.business_hours_end}): ${var.off_hours_min_capacity}-${var.off_hours_max_capacity} replicas
  - Weekend: 1-2 replicas
  - Monday Morning: Scale up for business

  MONITORING AUTOSCALING:
  --------------------

  # Check current replica count
  aws rds describe-db-clusters \
    --db-cluster-identifier ${module.aurora_autoscaling.cluster_ids["autoscaling"]} \
    --query 'DBClusters[0].DBClusterMembers' \
    --output table

  # View autoscaling activities
  aws application-autoscaling describe-scaling-activities \
    --service-namespace rds \
    --resource-id cluster:${module.aurora_autoscaling.cluster_ids["autoscaling"]} \
    --max-results 10

  # View CloudWatch metrics
  aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name CPUUtilization \
    --dimensions Name=DBClusterIdentifier,Value=${module.aurora_autoscaling.cluster_ids["autoscaling"]} \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average

  ==========================================
  EOT
}
