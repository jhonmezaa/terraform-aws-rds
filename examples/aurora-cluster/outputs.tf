output "cluster_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = module.aurora_mysql.cluster_endpoints["prod"]
}

output "cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = module.aurora_mysql.cluster_reader_endpoints["prod"]
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = module.aurora_mysql.cluster_arns["prod"]
}

output "cluster_members" {
  description = "Aurora cluster member instances"
  value       = module.aurora_mysql.cluster_members["prod"]
}
