# Aurora Limitless Database Example

This example demonstrates how to deploy **Aurora Limitless Database** for horizontal scaling beyond single-node Aurora limits using PostgreSQL 15.5+.

## What is Aurora Limitless Database?

Aurora Limitless Database is a new deployment option that enables horizontal scaling by:
- **Automatic sharding** across multiple compute nodes
- **Distributed query processing** for parallel execution
- **ACU-based scaling** from 768 to 3,145,728 ACU (0.75 TB to 3 PB)
- **Transparent to applications** - no code changes required

## Features Demonstrated

- ✅ Aurora Limitless with `cluster_scalability_type = "limitless"`
- ✅ Shard group configuration with ACU limits
- ✅ Compute redundancy for high availability
- ✅ AWS Secrets Manager for password management
- ✅ Performance Insights enabled
- ✅ CloudWatch Logs export

## Prerequisites

1. **VPC with at least 2 subnets** in different Availability Zones
2. **Security group** allowing PostgreSQL traffic (port 5432)
3. **Terraform >= 1.5.0**
4. **AWS Provider >= 5.0**

## Configuration

### 1. Copy and Edit Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your VPC, subnet, and security group IDs
```

### 2. Required Variables

Update these in `terraform.tfvars`:

```hcl
vpc_id                 = "vpc-xxxxx"                    # Your VPC ID
database_subnet_ids    = ["subnet-xxxxx", "subnet-yyyyy"] # At least 2 subnets
vpc_security_group_ids = ["sg-xxxxx"]                   # PostgreSQL access
```

### 3. Shard Group Configuration

```hcl
max_acu            = 1536 # Maximum capacity (768 to 3145728)
min_acu            = 768  # Minimum capacity
compute_redundancy = 2    # High availability (0, 1, or 2)
```

## Deployment

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
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

### 2. Connect with psql

```bash
# Get connection details
ENDPOINT=$(terraform output -raw cluster_endpoint)
PORT=$(terraform output -raw cluster_port)

# Connect
psql -h $ENDPOINT -p $PORT -U limitless_admin -d limitless_db
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Aurora Limitless Cluster                 │
│                                                           │
│  ┌──────────────┐   ┌──────────────┐                    │
│  │  Instance 1  │   │  Instance 2  │                    │
│  │ (r6g.xlarge) │   │ (r6g.xlarge) │                    │
│  └──────┬───────┘   └──────┬───────┘                    │
│         │                   │                            │
│         └────────┬──────────┘                            │
│                  │                                       │
│         ┌────────▼────────┐                              │
│         │  Shard Group    │                              │
│         │  768-1536 ACU   │                              │
│         │  Redundancy: 2  │                              │
│         └─────────────────┘                              │
│                                                           │
│  Horizontal Scaling • Distributed Queries • Auto-Sharding│
└─────────────────────────────────────────────────────────┘
```

## Shard Group Settings

| Parameter | Description | Range | Default |
|-----------|-------------|-------|---------|
| `max_acu` | Maximum capacity | 768 - 3,145,728 | 1536 |
| `min_acu` | Minimum capacity | 768 - max_acu | 768 |
| `compute_redundancy` | Redundancy level | 0, 1, 2 | 2 |

### Compute Redundancy Levels

- **0**: No redundancy (single compute node per shard)
- **1**: Single redundancy (2 compute nodes per shard)
- **2**: High availability (3 compute nodes per shard) - **Recommended for production**

## ACU to Storage Mapping

| ACU | Approximate Storage |
|-----|---------------------|
| 768 | 0.75 TB |
| 1,536 | 1.5 TB |
| 3,072 | 3 TB |
| 15,360 | 15 TB |
| 153,600 | 150 TB |
| 1,536,000 | 1.5 PB |
| 3,145,728 | 3 PB |

## Use Cases

Aurora Limitless is ideal for:

1. **Large-scale OLTP workloads** requiring > 1 million transactions/second
2. **Multi-tenant SaaS applications** with thousands of tenants
3. **Analytics workloads** requiring distributed parallel processing
4. **Gaming backends** with massive concurrent user loads
5. **Financial systems** needing horizontal scalability

## Monitoring

### CloudWatch Metrics

- Shard group CPU utilization
- Shard group storage usage
- Read/write IOPS per shard
- Connection count per shard

### Performance Insights

```bash
# View Performance Insights in AWS Console
aws rds describe-db-cluster-performance-insights \
  --db-cluster-identifier $(terraform output -raw cluster_id)
```

## Cost Optimization

1. **Right-size ACU settings** based on workload patterns
2. **Use compute_redundancy = 1** for non-production environments
3. **Enable auto-pause** for dev/test (when available)
4. **Monitor shard utilization** to adjust min/max ACU

## Limitations

- **PostgreSQL only**: Limitless requires PostgreSQL 15.5+
- **Minimum instance class**: db.r6g.xlarge or equivalent
- **Region availability**: Check AWS documentation for supported regions
- **Feature compatibility**: Some PostgreSQL extensions may not be supported

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Note: Set skip_final_snapshot = false in production to retain data
```

## Troubleshooting

### Issue: Cluster creation fails

**Solution**: Verify:
- PostgreSQL version is 15.5 or higher
- Instance class is db.r6g.xlarge or larger
- Subnets are in different Availability Zones
- Security group allows inbound PostgreSQL traffic

### Issue: Cannot connect to database

**Solution**: Check:
- Security group rules allow your IP address
- Cluster is in "available" state
- Using the correct endpoint from outputs
- Master password retrieved from Secrets Manager

## Related Examples

- [aurora-global-cluster](../aurora-global-cluster) - Multi-region disaster recovery
- [aurora-autoscaling-advanced](../aurora-autoscaling-advanced) - Advanced autoscaling patterns
- [aurora-postgresql-advanced](../aurora-postgresql-advanced) - Advanced PostgreSQL features

## References

- [Aurora Limitless Database Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-limitless.html)
- [PostgreSQL on Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/)
- [Aurora Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.BestPractices.html)
