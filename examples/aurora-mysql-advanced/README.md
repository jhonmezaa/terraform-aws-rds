# Aurora MySQL Advanced Example

This example demonstrates **advanced Aurora MySQL features** including Backtrack, binary log configuration, comprehensive CloudWatch logging, and MySQL-specific optimizations.

## What is Aurora MySQL?

Aurora MySQL is a MySQL-compatible relational database built for the cloud, combining the performance and availability of enterprise databases with the simplicity and cost-effectiveness of open-source databases.

## Features Demonstrated

- ✅ **Backtrack**: Rewind database to previous point in time without restore
- ✅ **Binary Log Configuration**: ROW, STATEMENT, or MIXED format
- ✅ **Comprehensive CloudWatch Logs**: audit, error, general, slowquery
- ✅ **Advanced Parameter Groups**: Cluster and instance-level MySQL tuning
- ✅ **Performance Insights**: Extended retention for performance analysis
- ✅ **Enhanced Monitoring**: 60-second granularity for detailed metrics
- ✅ **Multi-AZ High Availability**: 1 writer + 2 readers across AZs
- ✅ **Secrets Manager Integration**: Automatic password management

## Prerequisites

1. **VPC with at least 2 subnets** in different Availability Zones
2. **Security group** allowing MySQL traffic (port 3306)
3. **Terraform >= 1.5.0**
4. **AWS Provider >= 5.0**

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│            Aurora MySQL Cluster with Advanced Features            │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  Writer Instance (AZ-a)                   │   │
│  │                    db.r6g.large                           │   │
│  │              Read/Write Operations                        │   │
│  └───────────────────────┬──────────────────────────────────┘   │
│                          │                                        │
│                          │ Replication                            │
│                          │                                        │
│            ┌─────────────┴─────────────┐                         │
│            │                           │                         │
│  ┌─────────▼──────────┐    ┌──────────▼────────┐               │
│  │ Reader 1 (AZ-a)    │    │ Reader 2 (AZ-b)   │               │
│  │   db.r6g.large     │    │   db.r6g.large    │               │
│  │   Read Operations  │    │   Read Operations │               │
│  └────────────────────┘    └───────────────────┘               │
│                                                                    │
│  Features:                                                         │
│  • Backtrack: Rewind 24 hours without restore                    │
│  • Binary Logs: ROW format for safe replication                  │
│  • CloudWatch: audit + error + general + slowquery logs          │
│  • Parameters: Optimized for performance and monitoring          │
│                                                                    │
└──────────────────────────────────────────────────────────────────┘
```

## Configuration

### 1. Copy and Edit Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your VPC, subnet, and security group IDs
```

### 2. Required Variables

Update these in `terraform.tfvars`:

```hcl
vpc_id                 = "vpc-xxxxx"
database_subnet_ids    = ["subnet-xxxxx", "subnet-yyyyy"]
vpc_security_group_ids = ["sg-xxxxx"]
```

### 3. MySQL-Specific Configuration

#### Backtrack Window

```hcl
backtrack_window = 86400  # 24 hours in seconds
# backtrack_window = 259200 # 72 hours (maximum)
# backtrack_window = 0      # Disable backtrack
```

#### Binary Log Format

```hcl
binlog_format = "ROW" # ROW (recommended), STATEMENT, or MIXED
```

#### CloudWatch Logs

All MySQL log types are enabled:
- **audit**: Security and compliance auditing
- **error**: Error messages and warnings
- **general**: All queries (verbose - use with caution)
- **slowquery**: Queries exceeding threshold (2 seconds by default)

## Deployment

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

**Deployment time**: ~12-15 minutes (3 instances).

## MySQL Backtrack Feature

### What is Backtrack?

Backtrack allows you to **rewind your database** to a previous point in time **without restoring from a backup**. This is useful for recovering from:
- Accidental `DELETE` or `UPDATE` without `WHERE` clause
- Application bugs that corrupted data
- Schema changes you want to undo

### Key Characteristics

- **Fast**: Takes seconds vs minutes for traditional restore
- **In-place**: No new cluster creation required
- **Window**: Up to 72 hours (259200 seconds)
- **MySQL Only**: Not available for Aurora PostgreSQL
- **Must enable at creation**: Cannot be added later

### How to Use Backtrack

#### View Backtrack History

```bash
aws rds describe-db-cluster-backtracks \
  --db-cluster-identifier $(terraform output -raw cluster_id) \
  --max-records 20
```

#### Backtrack to Specific Time

```bash
# Backtrack to 1 hour ago
aws rds backtrack-db-cluster \
  --db-cluster-identifier $(terraform output -raw cluster_id) \
  --backtrack-to "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)"

# Backtrack to specific timestamp
aws rds backtrack-db-cluster \
  --db-cluster-identifier $(terraform output -raw cluster_id) \
  --backtrack-to "2024-01-15T10:30:00Z"
```

#### Check Backtrack Status

```bash
aws rds describe-db-clusters \
  --db-cluster-identifier $(terraform output -raw cluster_id) \
  --query 'DBClusters[0].BacktrackWindow'
```

### Backtrack Limitations

- **Requires downtime**: Brief DB instance restart during backtrack
- **Single point**: Cannot branch - overwrites current state
- **Not a backup**: Does not replace regular backups
- **Window limit**: Maximum 72 hours
- **Cost**: Additional storage for change records

### Backtrack vs Point-in-Time Restore

| Feature | Backtrack | PITR (Snapshot Restore) |
|---------|-----------|-------------------------|
| Speed | Seconds | 15-30 minutes |
| Downtime | Brief restart | Full restore time |
| New cluster | No | Yes |
| Cost | Change storage | Full snapshot + new cluster |
| Use case | Recent mistakes | Long-term recovery |

## Binary Log Configuration

### Binary Log Formats

#### ROW Format (Recommended)

```hcl
binlog_format = "ROW"
```

**Advantages**:
- Safest - logs actual data changes
- Required for multi-threaded replication
- Better for non-deterministic functions (NOW(), RAND())
- More reliable for replication

**Disadvantages**:
- Larger log files
- More storage required

#### STATEMENT Format

```hcl
binlog_format = "STATEMENT"
```

**Advantages**:
- Compact log files
- Less storage required
- Easier to review (human-readable SQL)

**Disadvantages**:
- Unsafe for non-deterministic functions
- Replication errors possible
- Not recommended for production

#### MIXED Format

```hcl
binlog_format = "MIXED"
```

**Behavior**: Automatically switches between ROW and STATEMENT based on query type.

### Viewing Binary Logs

```sql
-- Show binary log status
SHOW MASTER STATUS;

-- Show binary log events
SHOW BINLOG EVENTS IN 'mysql-bin.000001' LIMIT 10;

-- Show binary log file list
SHOW BINARY LOGS;
```

## CloudWatch Logs

### Accessing Logs

#### Slow Query Log

```bash
# Tail slow query log
aws logs tail /aws/rds/cluster/$(terraform output -raw cluster_id)/slowquery --follow

# Get slow queries from last hour
aws logs filter-log-events \
  --log-group-name /aws/rds/cluster/$(terraform output -raw cluster_id)/slowquery \
  --start-time $(($(date +%s) - 3600))000
```

#### Error Log

```bash
# Tail error log
aws logs tail /aws/rds/cluster/$(terraform output -raw cluster_id)/error --follow
```

#### Audit Log

```bash
# Tail audit log
aws logs tail /aws/rds/cluster/$(terraform output -raw cluster_id)/audit --follow
```

#### General Log

```bash
# Tail general log (verbose!)
aws logs tail /aws/rds/cluster/$(terraform output -raw cluster_id)/general --follow
```

**Warning**: General log captures ALL queries and can be extremely verbose. Enable only for debugging.

### Configuring Log Thresholds

#### Slow Query Threshold

```sql
-- Set slow query threshold to 1 second
SET GLOBAL long_query_time = 1;

-- Show current threshold
SHOW VARIABLES LIKE 'long_query_time';
```

This is configured in the cluster parameter group:

```hcl
long_query_time = {
  value        = "2"  # 2 seconds
  apply_method = "immediate"
}
```

#### Enable General Log (Dynamic)

```sql
-- Enable general log
SET GLOBAL general_log = 1;

-- Disable general log
SET GLOBAL general_log = 0;
```

## MySQL-Specific Parameters

### Cluster Parameters

Applied to the entire cluster:

```hcl
cluster_parameters = {
  binlog_format              = "ROW"
  character_set_server       = "utf8mb4"
  collation_server           = "utf8mb4_unicode_ci"
  time_zone                  = "UTC"
  max_connections            = "1000"
  slow_query_log             = "1"
  long_query_time            = "2"
  log_queries_not_using_indexes = "1"
  server_audit_logging       = "1"
  server_audit_events        = "CONNECT,QUERY,TABLE"
}
```

### Instance Parameters

Applied to individual instances:

```hcl
instance_parameters = {
  innodb_buffer_pool_size = "{DBInstanceClassMemory*3/4}" # 75% of RAM
  innodb_log_file_size    = "536870912"                   # 512 MB
  innodb_flush_method     = "O_DIRECT"
  max_allowed_packet      = "67108864"                    # 64 MB
}
```

### Viewing Parameters

```sql
-- Show all variables
SHOW VARIABLES;

-- Show specific variable
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';

-- Show InnoDB status
SHOW ENGINE INNODB STATUS\G

-- Show character set
SHOW VARIABLES LIKE 'character_set%';
```

## Connect to the Database

### 1. Retrieve the Password

```bash
# Get the secret ARN from outputs
SECRET_ARN=$(terraform output -raw master_user_secret_arn)

# Retrieve the password
aws secretsmanager get-secret-value \
  --secret-id $SECRET_ARN \
  --query SecretString --output text | jq -r .password
```

### 2. Connect with mysql Client

```bash
# Get connection details
ENDPOINT=$(terraform output -raw cluster_endpoint)
PORT=$(terraform output -raw cluster_port)

# Connect
mysql -h $ENDPOINT -p $PORT -u admin -p mysql_advanced_db
```

### 3. Verify Configuration

```sql
-- Check version
SELECT VERSION();

-- Check character set
SHOW VARIABLES LIKE 'character_set%';

-- Check binary log format
SHOW VARIABLES LIKE 'binlog_format';

-- Check InnoDB buffer pool
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';

-- Check slow query log
SHOW VARIABLES LIKE 'slow_query_log';
SHOW VARIABLES LIKE 'long_query_time';

-- Check audit logging
SHOW VARIABLES LIKE 'server_audit%';
```

## Performance Monitoring

### Performance Insights

```bash
# View Performance Insights
aws rds describe-db-cluster-performance-insights \
  --db-cluster-identifier $(terraform output -raw cluster_id)
```

### Enhanced Monitoring

CloudWatch metrics with 60-second granularity:
- CPU utilization
- Memory usage
- I/O operations
- Network throughput
- Active connections

```bash
# Get CPU metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBClusterIdentifier,Value=$(terraform output -raw cluster_id) \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### Slow Query Analysis

```sql
-- Find slow queries (if mysql.slow_log table exists)
SELECT
  sql_text,
  start_time,
  query_time,
  lock_time,
  rows_sent,
  rows_examined
FROM mysql.slow_log
ORDER BY query_time DESC
LIMIT 10;
```

## Best Practices

### 1. Backtrack Configuration

- **Enable at creation**: Cannot be added later
- **Set appropriate window**: Balance cost vs recovery needs
- **Document backtrack events**: Track when and why used
- **Test regularly**: Practice backtrack procedures

### 2. Binary Log Management

- **Use ROW format**: Safest for production
- **Monitor log size**: Can grow large with high write volume
- **Regular purging**: Aurora handles automatically
- **Replication safety**: ROW format prevents replication errors

### 3. CloudWatch Logs

- **Enable slow query log**: Essential for performance tuning
- **Disable general log**: Too verbose for production
- **Configure audit log**: For compliance requirements
- **Set retention**: Balance cost vs audit needs

### 4. Parameter Tuning

- **InnoDB buffer pool**: 70-80% of instance memory
- **Max connections**: Based on application requirements
- **Slow query threshold**: 1-2 seconds for OLTP
- **Character set**: utf8mb4 for emoji support

### 5. Monitoring

- **Performance Insights**: Enable for query analysis
- **Enhanced Monitoring**: 60-second granularity
- **CloudWatch alarms**: CPU, connections, replication lag
- **Regular reviews**: Weekly performance analysis

## Cost Optimization

### Instance Sizing

```hcl
# Production
instance_class = "db.r6g.large" # $0.29/hour

# Development
instance_class = "db.t3.medium" # $0.082/hour
```

### Backtrack Cost

Backtrack adds cost for change record storage:
- ~$0.024/GB-month for change records
- Typical: 1-5% of cluster storage cost

### Log Retention

CloudWatch Logs cost:
- Ingestion: $0.50/GB
- Storage: $0.03/GB-month
- Set retention: 7-30 days for cost control

## Troubleshooting

### Issue: Cannot enable backtrack

**Error**: "Backtrack is not supported for this DB cluster"

**Solution**:
- Backtrack must be enabled at cluster creation
- Cannot be enabled on existing clusters
- Requires specific engine versions (MySQL 5.6.mysql_aurora.1.19.5+, MySQL 5.7+, MySQL 8.0+)

### Issue: High slow query log volume

**Solution**:
```sql
-- Increase threshold
SET GLOBAL long_query_time = 5;

-- Disable logging queries not using indexes
SET GLOBAL log_queries_not_using_indexes = 0;
```

### Issue: General log filling CloudWatch

**Solution**:
```sql
-- Disable general log
SET GLOBAL general_log = 0;
```

Update parameter group to make permanent:
```hcl
general_log = {
  value        = "0"
  apply_method = "immediate"
}
```

### Issue: Binary log growing too large

**Analysis**: High write volume generates large binary logs

**Solution**:
- Aurora automatically manages binary log purging
- Check binlog retention: `SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';`
- Monitor storage usage in CloudWatch

## Cleanup

```bash
# Destroy all resources
terraform destroy
```

**Important**: Set `deletion_protection = false` before destroying.

## Related Examples

- [aurora-postgresql-advanced](../aurora-postgresql-advanced) - Advanced PostgreSQL features
- [aurora-autoscaling-advanced](../aurora-autoscaling-advanced) - Advanced autoscaling patterns
- [aurora-global-cluster](../aurora-global-cluster) - Multi-region disaster recovery

## References

- [Aurora MySQL Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.AuroraMySQL.html)
- [Backtrack Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Backtrack.html)
- [Binary Log Configuration](https://dev.mysql.com/doc/refman/8.0/en/replication-options-binary-log.html)
- [MySQL Performance Tuning](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
- [Aurora Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.BestPractices.html)
