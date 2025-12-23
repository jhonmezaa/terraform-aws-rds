# Aurora Global Cluster Example

This example demonstrates how to deploy **Aurora Global Database** for multi-region disaster recovery and low-latency global reads with PostgreSQL.

## What is Aurora Global Database?

Aurora Global Database is a feature that spans multiple AWS regions, enabling:
- **Cross-region read replicas** with sub-second replication latency
- **Disaster recovery** with RPO ~1 second and RTO ~1 minute
- **Global read scaling** by serving local reads from secondary regions
- **Write forwarding** from secondary regions to primary (optional)

## Features Demonstrated

- ✅ Global cluster spanning multiple AWS regions
- ✅ Primary cluster in us-east-1 (writer)
- ✅ Secondary cluster in us-west-2 (read replica with write forwarding)
- ✅ Cross-region replication with sub-second latency
- ✅ AWS Secrets Manager for password management
- ✅ Performance Insights enabled on all instances
- ✅ CloudWatch Logs export for monitoring

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                     Aurora Global Database                        │
│                                                                    │
│  ┌─────────────────────────┐      ┌─────────────────────────┐   │
│  │  PRIMARY REGION         │      │  SECONDARY REGION       │   │
│  │  (us-east-1)            │◄────►│  (us-west-2)            │   │
│  │                         │      │                         │   │
│  │  ┌──────────────────┐   │      │  ┌──────────────────┐   │   │
│  │  │ Primary Cluster  │   │      │  │ Secondary Cluster│   │   │
│  │  │                  │   │      │  │                  │   │   │
│  │  │ ┌──────────────┐ │   │      │  │ ┌──────────────┐ │   │   │
│  │  │ │ Writer (AZ-a)│ │   │ Repl │  │ │ Reader (AZ-a)│ │   │   │
│  │  │ └──────────────┘ │   │◄────►│  │ └──────────────┘ │   │   │
│  │  │ ┌──────────────┐ │   │ <1s  │  │ ┌──────────────┐ │   │   │
│  │  │ │ Reader (AZ-b)│ │   │      │  │ │ Reader (AZ-b)│ │   │   │
│  │  │ └──────────────┘ │   │      │  │ └──────────────┘ │   │   │
│  │  └──────────────────┘   │      │  └──────────────────┘   │   │
│  │         │                │      │         │               │   │
│  │         ▼                │      │         ▼               │   │
│  │   Read/Write             │      │   Read + Write          │   │
│  │   Operations             │      │   Forwarding ────────┐  │   │
│  └─────────────────────────┘      └──────────────────────│──┘   │
│                                                           │      │
│                        Write Forwarding Enabled          │      │
│                        (Forwards to Primary) ◄───────────┘      │
└──────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Primary Region (us-east-1)
1. **VPC** with at least 2 subnets in different Availability Zones
2. **Security group** allowing PostgreSQL traffic (port 5432)

### Secondary Region (us-west-2)
1. **VPC** with at least 2 subnets in different Availability Zones
2. **Security group** allowing PostgreSQL traffic (port 5432)

### AWS Credentials
- AWS credentials with permissions to create RDS resources in **both regions**
- Terraform >= 1.5.0
- AWS Provider >= 5.0

## Configuration

### 1. Copy and Edit Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your VPC, subnet, and security group IDs
```

### 2. Required Variables

Update these in `terraform.tfvars`:

```hcl
# Primary Region (us-east-1)
primary_vpc_security_group_ids = ["sg-xxxxx"]
primary_database_subnet_ids    = ["subnet-xxxxx", "subnet-yyyyy"]

# Secondary Region (us-west-2)
secondary_vpc_security_group_ids = ["sg-zzzzz"]
secondary_database_subnet_ids    = ["subnet-aaaaa", "subnet-bbbbb"]
```

### 3. Optional Customization

```hcl
# Change regions
primary_region   = "eu-west-1"
secondary_region = "ap-southeast-1"

# Change instance class
instance_class = "db.r6g.xlarge"

# Enable deletion protection
deletion_protection = true
```

## Deployment

```bash
# Initialize Terraform
terraform init

# Review the plan (notice resources in both regions)
terraform plan

# Apply the configuration
terraform apply
```

**Note**: The global cluster and primary cluster will be created first, followed by the secondary cluster. Total deployment time: ~15-20 minutes.

## Connect to the Database

### 1. Retrieve the Password

Master credentials are stored in Secrets Manager in the **primary region**:

```bash
# Get the secret ARN from outputs
SECRET_ARN=$(terraform output -raw primary_master_user_secret_arn)

# Retrieve the password
aws secretsmanager get-secret-value \
  --region us-east-1 \
  --secret-id $SECRET_ARN \
  --query SecretString --output text | jq -r .password
```

### 2. Connect to Primary Cluster (Read/Write)

```bash
# Get connection details
PRIMARY_ENDPOINT=$(terraform output -raw primary_cluster_endpoint)
PORT=$(terraform output -raw primary_cluster_port)

# Connect
psql -h $PRIMARY_ENDPOINT -p $PORT -U dbadmin -d globaldb
```

### 3. Connect to Secondary Cluster (Read + Write Forwarding)

```bash
# Get secondary endpoint
SECONDARY_ENDPOINT=$(terraform output -raw secondary_cluster_endpoint)

# Connect
psql -h $SECONDARY_ENDPOINT -p $PORT -U dbadmin -d globaldb
```

**Note**: The secondary cluster has **write forwarding enabled**, meaning:
- Read queries execute locally in us-west-2 (low latency)
- Write queries are forwarded to primary in us-east-1 (slightly higher latency)

## Disaster Recovery Procedures

### Monitoring Replication

```bash
# Check global cluster status
aws rds describe-global-clusters \
  --global-cluster-identifier $(terraform output -raw global_cluster_id)

# Check replication lag (should be < 1 second)
aws rds describe-db-clusters \
  --db-cluster-identifier $(terraform output -raw secondary_cluster_id) \
  --region us-west-2 \
  --query 'DBClusters[0].ReplicationSourceIdentifier'
```

### Planned Failover (No Data Loss)

Use this for maintenance windows or region migrations:

```bash
# 1. Stop writes to primary cluster
# 2. Wait for replication to catch up
# 3. Initiate failover
aws rds failover-global-cluster \
  --global-cluster-identifier $(terraform output -raw global_cluster_id) \
  --target-db-cluster-identifier $(terraform output -raw secondary_cluster_id) \
  --region us-west-2

# 4. Update application endpoints to point to new primary (us-west-2)
```

**Result**: Secondary becomes the new primary. Previous primary becomes a secondary.

### Unplanned Failover (Disaster Recovery)

Use this if the primary region becomes unavailable:

```bash
# 1. Detach secondary from global cluster
aws rds remove-from-global-cluster \
  --db-cluster-identifier $(terraform output -raw secondary_cluster_id) \
  --region us-west-2

# 2. Promote secondary to standalone cluster
# (This happens automatically when detached)

# 3. Update application to use new primary endpoint
```

**Result**: Secondary becomes standalone cluster. RPO ~1 second, RTO ~1 minute.

### Failing Back to Original Primary

After the primary region is restored:

```bash
# 1. Create new secondary from current primary
aws rds create-db-cluster \
  --global-cluster-identifier $(terraform output -raw global_cluster_id) \
  --db-cluster-identifier restored-primary \
  --engine aurora-postgresql \
  --region us-east-1

# 2. Wait for replication to synchronize
# 3. Failover back to original region (planned failover steps above)
```

## Testing the Setup

### Test Cross-Region Replication

```bash
# 1. Connect to primary and create test data
psql -h $PRIMARY_ENDPOINT -p $PORT -U dbadmin -d globaldb

# In psql:
CREATE TABLE test_replication (
  id SERIAL PRIMARY KEY,
  message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO test_replication (message) VALUES ('Hello from us-east-1');

# 2. Connect to secondary and verify data
psql -h $SECONDARY_ENDPOINT -p $PORT -U dbadmin -d globaldb

# In psql:
SELECT * FROM test_replication;
-- Should show the record within 1 second
```

### Test Write Forwarding

```bash
# Connect to secondary cluster
psql -h $SECONDARY_ENDPOINT -p $PORT -U dbadmin -d globaldb

# In psql (write on secondary):
INSERT INTO test_replication (message) VALUES ('Written on secondary, forwarded to primary');

# This write will be forwarded to primary and replicated back
# Slightly higher latency than writing directly to primary
```

## Cost Optimization

### Development/Testing
```hcl
instance_class      = "db.t3.medium"
deletion_protection = false
```

### Production
```hcl
instance_class      = "db.r6g.large"
deletion_protection = true
```

### Cost Components
- **Primary cluster**: 2 instances (writer + reader)
- **Secondary cluster**: 2 read replicas
- **Cross-region data transfer**: Replication between regions
- **Storage**: Charged per region
- **I/O operations**: Per region

## Monitoring

### CloudWatch Metrics

Key metrics to monitor:

```bash
# Replication lag (should be < 1000ms)
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name AuroraGlobalDBReplicationLag \
  --dimensions Name=DBClusterIdentifier,Value=$(terraform output -raw secondary_cluster_id) \
  --region us-west-2 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# Replicated bytes
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name AuroraGlobalDBReplicatedBytes \
  --dimensions Name=DBClusterIdentifier,Value=$(terraform output -raw secondary_cluster_id) \
  --region us-west-2 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

### Performance Insights

```bash
# View Performance Insights for primary cluster
aws rds describe-db-cluster-performance-insights \
  --db-cluster-identifier $(terraform output -raw primary_cluster_id) \
  --region us-east-1

# View Performance Insights for secondary cluster
aws rds describe-db-cluster-performance-insights \
  --db-cluster-identifier $(terraform output -raw secondary_cluster_id) \
  --region us-west-2
```

## Best Practices

### Network Configuration
1. **Use private subnets** for database instances
2. **Enable encryption in transit** (SSL/TLS)
3. **Restrict security groups** to application subnets only
4. **Use VPC peering** for cross-region application access

### High Availability
1. **Multiple instances per cluster** (at least 2)
2. **Instances in different AZs** for zone-level resilience
3. **Enable deletion protection** in production
4. **Regular backups** (enabled by default)

### Performance
1. **Use read endpoints** for read-only queries in each region
2. **Enable write forwarding** for applications in secondary regions
3. **Monitor replication lag** to ensure data freshness
4. **Use connection pooling** (e.g., RDS Proxy)

### Cost Management
1. **Right-size instance classes** based on workload
2. **Use Aurora Serverless v2** for variable workloads
3. **Monitor cross-region data transfer** costs
4. **Consider instance count** per region

## Limitations

- **Maximum 5 secondary regions** per global cluster
- **PostgreSQL and MySQL only** (RDS PostgreSQL/MySQL not supported)
- **Engine version must match** across all clusters
- **Parameter groups inherited** from primary cluster
- **Replication lag** depends on data transfer volume and network latency
- **Write forwarding** adds latency (round-trip to primary region)

## Troubleshooting

### Issue: Secondary cluster fails to create

**Solution**: Ensure:
- Global cluster is fully created before secondary
- Engine version matches primary cluster
- Subnets are in different Availability Zones
- Security group allows traffic from primary region (if using private subnets)

### Issue: High replication lag

**Solution**: Check:
- Network connectivity between regions
- Write volume on primary cluster
- I/O capacity on secondary instances
- CloudWatch metrics for throttling

### Issue: Cannot connect to database

**Solution**: Verify:
- Security group allows your IP address
- Using correct endpoint (writer vs reader)
- Password retrieved from correct region (primary)
- Cluster is in "available" state

### Issue: Write forwarding not working

**Solution**: Confirm:
- `enable_global_write_forwarding = true` on secondary cluster
- Aurora engine version supports write forwarding (PostgreSQL 13.6+)
- Connected to secondary cluster endpoint
- Using a supported PostgreSQL client

## Cleanup

```bash
# Destroy all resources (both regions)
terraform destroy
```

**Important**: Set `deletion_protection = false` before destroying production clusters.

## Related Examples

- [aurora-limitless](../aurora-limitless) - Horizontal scaling with Aurora Limitless
- [aurora-autoscaling-advanced](../aurora-autoscaling-advanced) - Advanced autoscaling patterns
- [aurora-postgresql-advanced](../aurora-postgresql-advanced) - Advanced PostgreSQL features

## References

- [Aurora Global Database Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html)
- [Write Forwarding](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-write-forwarding.html)
- [Disaster Recovery](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database-disaster-recovery.html)
- [Aurora Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.BestPractices.html)
