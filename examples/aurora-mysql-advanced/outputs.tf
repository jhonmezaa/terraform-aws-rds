# =============================================================================
# Cluster Outputs
# =============================================================================

output "cluster_id" {
  description = "Aurora MySQL cluster identifier"
  value       = module.aurora_mysql.cluster_ids["mysql"]
}

output "cluster_arn" {
  description = "Aurora MySQL cluster ARN"
  value       = module.aurora_mysql.cluster_arns["mysql"]
}

output "cluster_endpoint" {
  description = "Aurora MySQL cluster writer endpoint"
  value       = module.aurora_mysql.cluster_endpoints["mysql"]
}

output "cluster_reader_endpoint" {
  description = "Aurora MySQL cluster reader endpoint"
  value       = module.aurora_mysql.cluster_reader_endpoints["mysql"]
}

output "cluster_port" {
  description = "Aurora MySQL cluster port"
  value       = module.aurora_mysql.cluster_ports["mysql"]
}

output "cluster_resource_id" {
  description = "Aurora MySQL cluster resource ID"
  value       = module.aurora_mysql.cluster_resource_ids["mysql"]
}

# =============================================================================
# Backtrack Outputs (MySQL-specific)
# =============================================================================

output "backtrack_window" {
  description = "Backtrack window in seconds (0 = disabled)"
  value       = var.backtrack_window
}

output "backtrack_enabled" {
  description = "Whether backtrack is enabled"
  value       = var.backtrack_window > 0
}

# =============================================================================
# Secrets Manager Outputs
# =============================================================================

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing master user credentials"
  value       = module.aurora_mysql.cluster_master_user_secret_arns["mysql"]
  sensitive   = true
}

# =============================================================================
# Instance Outputs
# =============================================================================

output "instance_ids" {
  description = "Map of instance identifiers"
  value       = module.aurora_mysql.cluster_instance_ids
}

output "instance_endpoints" {
  description = "Map of instance endpoints"
  value       = module.aurora_mysql.cluster_instance_endpoints
}

# =============================================================================
# Parameter Group Outputs
# =============================================================================

output "cluster_parameter_group_id" {
  description = "Cluster parameter group ID"
  value       = module.aurora_mysql.cluster_parameter_group_ids["mysql"]
}

output "db_parameter_group_ids" {
  description = "Map of DB parameter group IDs"
  value       = module.aurora_mysql.db_parameter_group_ids
}

# =============================================================================
# Usage Instructions
# =============================================================================

output "connection_info" {
  description = "Connection information for Aurora MySQL cluster"
  value       = <<-EOT

  ==========================================
  Aurora MySQL Advanced Features Enabled!
  ==========================================

  Cluster Endpoint: ${module.aurora_mysql.cluster_endpoints["mysql"]}
  Reader Endpoint:  ${module.aurora_mysql.cluster_reader_endpoints["mysql"]}
  Port: ${module.aurora_mysql.cluster_ports["mysql"]}
  Database: ${var.database_name}

  HOW TO CONNECT:
  --------------------

  1. Retrieve the master password from Secrets Manager:

     aws secretsmanager get-secret-value \
       --secret-id ${module.aurora_mysql.cluster_master_user_secret_arns["mysql"]} \
       --query SecretString --output text | jq -r .password

  2. Connect using mysql client:

     mysql -h ${module.aurora_mysql.cluster_endpoints["mysql"]} \
           -P ${module.aurora_mysql.cluster_ports["mysql"]} \
           -u ${var.db_username} \
           -p ${var.database_name}

  MYSQL ADVANCED FEATURES:
  --------------------

  ✓ Backtrack: ${var.backtrack_window > 0 ? "Enabled (${var.backtrack_window / 3600} hours)" : "Disabled"}
  ✓ Binary Log Format: ${var.binlog_format}
  ✓ CloudWatch Logs: audit, error, general, slowquery
  ✓ Performance Insights: ${var.performance_insights_retention_period} days retention
  ✓ Enhanced Monitoring: 60-second granularity
  ✓ Backup Retention: ${var.backup_retention_period} days
  ✓ Instances: 1 writer + 2 readers (Multi-AZ)

  BACKTRACK USAGE:
  --------------------

  # View backtrack history
  aws rds describe-db-cluster-backtracks \
    --db-cluster-identifier ${module.aurora_mysql.cluster_ids["mysql"]} \
    --max-records 20

  # Backtrack to 1 hour ago
  aws rds backtrack-db-cluster \
    --db-cluster-identifier ${module.aurora_mysql.cluster_ids["mysql"]} \
    --backtrack-to "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" \
    --use-earliest-time-on-point-in-time-unavailable

  # Backtrack to specific timestamp
  aws rds backtrack-db-cluster \
    --db-cluster-identifier ${module.aurora_mysql.cluster_ids["mysql"]} \
    --backtrack-to "2024-01-15T10:30:00Z"

  CLOUDWATCH LOGS:
  --------------------

  # View slow query logs
  aws logs tail /aws/rds/cluster/${module.aurora_mysql.cluster_ids["mysql"]}/slowquery --follow

  # View error logs
  aws logs tail /aws/rds/cluster/${module.aurora_mysql.cluster_ids["mysql"]}/error --follow

  # View audit logs
  aws logs tail /aws/rds/cluster/${module.aurora_mysql.cluster_ids["mysql"]}/audit --follow

  MYSQL QUERY EXAMPLES:
  --------------------

  -- Check replication status
  SHOW SLAVE STATUS\G

  -- View binary log position
  SHOW MASTER STATUS;

  -- Check slow queries
  SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;

  -- View character set
  SHOW VARIABLES LIKE 'character_set%';

  -- Check InnoDB status
  SHOW ENGINE INNODB STATUS\G

  -- View current connections
  SHOW PROCESSLIST;

  PERFORMANCE INSIGHTS:
  --------------------

  # View Performance Insights in AWS Console
  aws rds describe-db-cluster-performance-insights \
    --db-cluster-identifier ${module.aurora_mysql.cluster_ids["mysql"]}

  IMPORTANT NOTES:
  --------------------
  • Backtrack requires backtrack_window > 0 during creation
  • Backtrack causes a brief DB instance restart
  • Binlog format ROW is recommended for replication
  • General log can be very verbose - enable only for debugging
  • Slow query log helps identify performance bottlenecks
  • Audit logs are useful for security and compliance

  ==========================================
  EOT
}
