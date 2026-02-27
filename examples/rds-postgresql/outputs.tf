output "primary_endpoint" {
  description = "Primary RDS instance endpoint"
  value       = module.rds_postgresql.db_instance_endpoints["primary"]
}

output "primary_arn" {
  description = "Primary RDS instance ARN"
  value       = module.rds_postgresql.db_instance_arns["primary"]
}

output "replica_endpoint" {
  description = "Read replica endpoint"
  value       = module.rds_postgresql.db_instance_endpoints["replica"]
}

output "primary_port" {
  description = "Primary RDS instance port"
  value       = module.rds_postgresql.db_instance_ports["primary"]
}

output "database_name" {
  description = "Database name"
  value       = module.rds_postgresql.db_instance_database_names["primary"]
}
