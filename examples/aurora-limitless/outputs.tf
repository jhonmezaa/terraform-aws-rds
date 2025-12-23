# =============================================================================
# Cluster Outputs
# =============================================================================

output "cluster_id" {
  description = "Aurora cluster identifier"
  value       = module.aurora_limitless.cluster_ids["limitless"]
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = module.aurora_limitless.cluster_arns["limitless"]
}

output "cluster_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = module.aurora_limitless.cluster_endpoints["limitless"]
}

output "cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = module.aurora_limitless.cluster_reader_endpoints["limitless"]
}

output "cluster_port" {
  description = "Aurora cluster port"
  value       = module.aurora_limitless.cluster_ports["limitless"]
}

output "cluster_scalability_type" {
  description = "Cluster scalability type (should be 'limitless')"
  value       = module.aurora_limitless.cluster_scalability_types["limitless"]
}

# =============================================================================
# Secrets Manager Outputs
# =============================================================================

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing master user credentials"
  value       = module.aurora_limitless.cluster_master_user_secret_arns["limitless"]
  sensitive   = true
}

# =============================================================================
# Instance Outputs
# =============================================================================

output "instance_ids" {
  description = "Map of instance identifiers"
  value       = module.aurora_limitless.cluster_instance_ids
}

output "instance_endpoints" {
  description = "Map of instance endpoints"
  value       = module.aurora_limitless.cluster_instance_endpoints
}

# =============================================================================
# Usage Instructions
# =============================================================================

output "connection_info" {
  description = "Connection information for Aurora Limitless cluster"
  value       = <<-EOT

  ==========================================
  Aurora Limitless Database Created!
  ==========================================

  Cluster Endpoint: ${module.aurora_limitless.cluster_endpoints["limitless"]}
  Port: ${module.aurora_limitless.cluster_ports["limitless"]}
  Database: limitless_db
  Scalability: ${module.aurora_limitless.cluster_scalability_types["limitless"]}

  HOW TO CONNECT:
  --------------------

  1. Retrieve the master password from Secrets Manager:

     aws secretsmanager get-secret-value \
       --secret-id ${module.aurora_limitless.cluster_master_user_secret_arns["limitless"]} \
       --query SecretString --output text | jq -r .password

  2. Connect using psql:

     psql -h ${module.aurora_limitless.cluster_endpoints["limitless"]} \
          -p ${module.aurora_limitless.cluster_ports["limitless"]} \
          -U ${var.db_username} \
          -d limitless_db

  AURORA LIMITLESS FEATURES:
  --------------------
  - Horizontal scaling beyond single-node limits
  - Automated shard management
  - Distributed query processing
  - ACU-based scaling: ${var.min_acu} to ${var.max_acu} ACU
  - Compute redundancy: ${var.compute_redundancy}

  NOTE: Aurora Limitless is designed for workloads requiring
  horizontal scalability beyond traditional Aurora limits.

  ==========================================
  EOT
}
