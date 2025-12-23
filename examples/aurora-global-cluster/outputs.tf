# =============================================================================
# Global Cluster Outputs
# =============================================================================

output "global_cluster_id" {
  description = "Global cluster identifier"
  value       = module.aurora_primary.global_cluster_ids["main"]
}

output "global_cluster_arn" {
  description = "Global cluster ARN"
  value       = module.aurora_primary.global_cluster_arns["main"]
}

output "global_cluster_resource_id" {
  description = "Global cluster resource ID"
  value       = module.aurora_primary.global_cluster_resource_ids["main"]
}

# =============================================================================
# Primary Cluster Outputs (us-east-1)
# =============================================================================

output "primary_cluster_id" {
  description = "Primary cluster identifier"
  value       = module.aurora_primary.cluster_ids["primary"]
}

output "primary_cluster_arn" {
  description = "Primary cluster ARN"
  value       = module.aurora_primary.cluster_arns["primary"]
}

output "primary_cluster_endpoint" {
  description = "Primary cluster writer endpoint"
  value       = module.aurora_primary.cluster_endpoints["primary"]
}

output "primary_cluster_reader_endpoint" {
  description = "Primary cluster reader endpoint"
  value       = module.aurora_primary.cluster_reader_endpoints["primary"]
}

output "primary_cluster_port" {
  description = "Primary cluster port"
  value       = module.aurora_primary.cluster_ports["primary"]
}

output "primary_master_user_secret_arn" {
  description = "ARN of Secrets Manager secret for primary cluster credentials"
  value       = module.aurora_primary.cluster_master_user_secret_arns["primary"]
  sensitive   = true
}

output "primary_instance_ids" {
  description = "Map of primary cluster instance identifiers"
  value       = module.aurora_primary.cluster_instance_ids
}

output "primary_instance_endpoints" {
  description = "Map of primary cluster instance endpoints"
  value       = module.aurora_primary.cluster_instance_endpoints
}

# =============================================================================
# Secondary Cluster Outputs (us-west-2)
# =============================================================================

output "secondary_cluster_id" {
  description = "Secondary cluster identifier"
  value       = module.aurora_secondary.cluster_ids["secondary"]
}

output "secondary_cluster_arn" {
  description = "Secondary cluster ARN"
  value       = module.aurora_secondary.cluster_arns["secondary"]
}

output "secondary_cluster_endpoint" {
  description = "Secondary cluster writer endpoint (read-only, forwards writes to primary)"
  value       = module.aurora_secondary.cluster_endpoints["secondary"]
}

output "secondary_cluster_reader_endpoint" {
  description = "Secondary cluster reader endpoint"
  value       = module.aurora_secondary.cluster_reader_endpoints["secondary"]
}

output "secondary_cluster_port" {
  description = "Secondary cluster port"
  value       = module.aurora_secondary.cluster_ports["secondary"]
}

output "secondary_instance_ids" {
  description = "Map of secondary cluster instance identifiers"
  value       = module.aurora_secondary.cluster_instance_ids
}

output "secondary_instance_endpoints" {
  description = "Map of secondary cluster instance endpoints"
  value       = module.aurora_secondary.cluster_instance_endpoints
}

# =============================================================================
# Connection Information
# =============================================================================

output "connection_info" {
  description = "Connection information for Aurora Global Cluster"
  value       = <<-EOT

  ==========================================
  Aurora Global Cluster Created!
  ==========================================

  GLOBAL CLUSTER:
  --------------------
  Global Cluster ID: ${module.aurora_primary.global_cluster_ids["main"]}
  Engine: aurora-postgresql ${var.engine_version}
  Database: ${var.database_name}

  PRIMARY CLUSTER (${var.primary_region}):
  --------------------
  Cluster Endpoint: ${module.aurora_primary.cluster_endpoints["primary"]}
  Reader Endpoint:  ${module.aurora_primary.cluster_reader_endpoints["primary"]}
  Port: ${module.aurora_primary.cluster_ports["primary"]}
  Role: Writer (Primary)
  Instances: 2 (writer + reader)

  SECONDARY CLUSTER (${var.secondary_region}):
  --------------------
  Cluster Endpoint: ${module.aurora_secondary.cluster_endpoints["secondary"]}
  Reader Endpoint:  ${module.aurora_secondary.cluster_reader_endpoints["secondary"]}
  Port: ${module.aurora_secondary.cluster_ports["secondary"]}
  Role: Read Replica (writes forwarded to primary)
  Instances: 2 (readers with write forwarding)

  HOW TO CONNECT:
  --------------------

  1. Retrieve master password from Secrets Manager:

     aws secretsmanager get-secret-value \
       --region ${var.primary_region} \
       --secret-id ${module.aurora_primary.cluster_master_user_secret_arns["primary"]} \
       --query SecretString --output text | jq -r .password

  2. Connect to PRIMARY cluster (read/write):

     psql -h ${module.aurora_primary.cluster_endpoints["primary"]} \
          -p ${module.aurora_primary.cluster_ports["primary"]} \
          -U ${var.db_username} \
          -d ${var.database_name}

  3. Connect to SECONDARY cluster (read-only, writes forwarded):

     psql -h ${module.aurora_secondary.cluster_endpoints["secondary"]} \
          -p ${module.aurora_secondary.cluster_ports["secondary"]} \
          -U ${var.db_username} \
          -d ${var.database_name}

  DISASTER RECOVERY:
  --------------------
  - Cross-region replication: Active
  - Write forwarding: Enabled on secondary
  - RPO (Recovery Point Objective): ~1 second
  - RTO (Recovery Time Objective): ~1 minute (manual failover)

  To failover to secondary region:
  aws rds failover-global-cluster \
    --global-cluster-identifier ${module.aurora_primary.global_cluster_ids["main"]} \
    --target-db-cluster-identifier ${module.aurora_secondary.cluster_ids["secondary"]} \
    --region ${var.secondary_region}

  ==========================================
  EOT
}
