output "instance_endpoint" {
  description = "RDS MySQL instance endpoint"
  value       = module.rds_mysql.db_instance_endpoints["main"]
}

output "instance_arn" {
  description = "RDS MySQL instance ARN"
  value       = module.rds_mysql.db_instance_arns["main"]
}

output "instance_port" {
  description = "RDS MySQL instance port"
  value       = module.rds_mysql.db_instance_ports["main"]
}

output "database_name" {
  description = "Database name"
  value       = module.rds_mysql.db_instance_database_names["main"]
}

output "option_group_id" {
  description = "Option group ID"
  value       = module.rds_mysql.db_option_group_ids["main"]
}
