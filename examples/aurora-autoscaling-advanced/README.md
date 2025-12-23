# Aurora Advanced Autoscaling Example

This example demonstrates **advanced autoscaling patterns** for Aurora PostgreSQL, including target tracking, step scaling, and scheduled actions for cost-optimized, performance-driven capacity management.

## What is Aurora Autoscaling?

Aurora Autoscaling automatically adjusts the number of Aurora read replicas in response to workload changes, providing:
- **Automatic capacity adjustment** based on metrics (CPU, connections)
- **Cost optimization** by scaling down during low traffic
- **Performance maintenance** by scaling out during high traffic
- **Scheduled capacity changes** for predictable workload patterns

## Features Demonstrated

- ✅ **Target Tracking Autoscaling**: CPU and connection-based triggers
- ✅ **Step Scaling Policies**: Fine-grained control for extreme scenarios
- ✅ **Scheduled Actions**: Business hours vs off-hours capacity
- ✅ **Multiple Autoscaling Triggers**: Composite scaling decisions
- ✅ **Cooldown Periods**: Prevent scaling oscillations
- ✅ **Performance Insights**: Monitor scaling effectiveness
- ✅ **CloudWatch Integration**: Track autoscaling activities

## Prerequisites

1. **VPC with at least 2 subnets** in different Availability Zones
2. **Security group** allowing PostgreSQL traffic (port 5432)
3. **Terraform >= 1.5.0**
4. **AWS Provider >= 5.0**

## Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│              Aurora Cluster with Advanced Autoscaling               │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Writer Instance (Fixed)                    │  │
│  │                     db.r6g.large (AZ-a)                       │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                 │                                    │
│                                 │                                    │
│  ┌──────────────────────────────┴──────────────────────────────┐  │
│  │          Read Replicas (Auto-scaling: 1 to 5 instances)      │  │
│  │                                                               │  │
│  │  Triggered by:                                                │  │
│  │  • CPU > 70% → Scale Out                                      │  │
│  │  • Connections > 500 → Scale Out                              │  │
│  │  • CPU < 20% (sustained) → Scale In                           │  │
│  │  • Scheduled: Business hours (3-10), Off-hours (1-3)          │  │
│  │                                                               │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │  │
│  │  │ Reader 1 │  │ Reader 2 │  │ Reader 3 │  │ Reader N │     │  │
│  │  │  (AZ-a)  │  │  (AZ-b)  │  │  (AZ-a)  │  │  (AZ-b)  │     │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘     │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  Scaling Policies:                                                   │
│  • Target Tracking: CPU (70%), Connections (500)                    │
│  • Step Scaling: Aggressive scale-out when CPU > 80%                │
│  • Scheduled: Business hours (8 AM-6 PM Mon-Fri)                    │
│                                                                      │
└────────────────────────────────────────────────────────────────────┘
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

### 3. Autoscaling Configuration

#### Base Capacity

```hcl
min_capacity = 1  # Always maintain at least 1 read replica
max_capacity = 5  # Never exceed 5 read replicas
```

#### Target Tracking

```hcl
cpu_target_value         = 70  # Scale when CPU exceeds 70%
connections_target_value = 500 # Scale when connections exceed 500
```

#### Scheduled Actions

```hcl
# Business hours: 8 AM - 6 PM Mon-Fri
business_hours_min_capacity = 3
business_hours_max_capacity = 10

# Off-hours: Evenings and weekends
off_hours_min_capacity = 1
off_hours_max_capacity = 3
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

**Deployment time**: ~10-12 minutes for initial cluster + 1 read replica.

## Autoscaling Policies Explained

### 1. Target Tracking Policies

Target tracking automatically adjusts capacity to maintain target metrics:

#### CPU-Based Scaling

```hcl
cpu = {
  target_metric       = "RDSReaderAverageCPUUtilization"
  target_value        = 70      # Target 70% CPU
  scale_in_cooldown   = 300     # Wait 5 min before scale-in
  scale_out_cooldown  = 60      # Wait 1 min before scale-out
}
```

**How it works**:
- When average CPU across readers > 70%: Add replicas
- When average CPU < 70% (sustained): Remove replicas
- Fast scale-out (60s), conservative scale-in (300s)

#### Connection-Based Scaling

```hcl
connections = {
  target_metric       = "RDSReaderAverageDatabaseConnections"
  target_value        = 500
  scale_in_cooldown   = 600     # Wait 10 min before scale-in
  scale_out_cooldown  = 120     # Wait 2 min before scale-out
}
```

**How it works**:
- When average connections > 500: Add replicas
- Longer cooldowns to avoid connection pool fluctuations

**Combined behavior**: Scales out if **ANY** metric exceeds target, scales in only if **ALL** metrics are below target.

### 2. Step Scaling Policies

Step scaling provides fine-grained control for extreme scenarios:

#### Aggressive Scale-Out (CPU > 80%)

```hcl
step_adjustments = [
  {
    scaling_adjustment = 50   # Add 50% capacity
    metric_interval_lower_bound = 80
    metric_interval_upper_bound = 90
  },
  {
    scaling_adjustment = 100  # Double capacity
    metric_interval_lower_bound = 90
  }
]
```

**Example**: If you have 2 replicas and CPU hits 85%:
- 50% increase = Add 1 replica (2 × 0.5 = 1)
- New total: 3 replicas

If CPU hits 95%:
- 100% increase = Add 2 replicas (2 × 1.0 = 2)
- New total: 4 replicas

#### Conservative Scale-In (CPU < 20%)

```hcl
step_adjustments = [
  {
    scaling_adjustment = -1   # Remove 1 replica
    metric_interval_upper_bound = 20
  }
]
```

**Why step scaling?**: Provides faster, more aggressive response than target tracking alone during extreme load spikes.

### 3. Scheduled Actions

Scheduled actions override min/max capacity at specific times:

#### Business Hours (8 AM Mon-Fri)

```hcl
business_hours_start = {
  schedule     = "cron(0 8 ? * MON-FRI *)"
  min_capacity = 3   # Start day with 3 replicas
  max_capacity = 10  # Allow scaling to 10 if needed
}
```

#### Off-Hours (6 PM Mon-Fri)

```hcl
business_hours_end = {
  schedule     = "cron(0 18 ? * MON-FRI *)"
  min_capacity = 1   # Scale down to 1 replica
  max_capacity = 3   # Limit scale-out
}
```

#### Weekend (Saturday 12 AM)

```hcl
weekend_start = {
  schedule     = "cron(0 0 ? * SAT *)"
  min_capacity = 1
  max_capacity = 2
}
```

#### Monday Morning Prep (Monday 6 AM)

```hcl
monday_morning = {
  schedule     = "cron(0 6 ? * MON *)"
  min_capacity = 3   # Pre-scale for business hours
  max_capacity = 10
}
```

**Cron format**: `cron(minute hour day-of-month month day-of-week year)`

## Monitoring Autoscaling

### Check Current Replica Count

```bash
# View all cluster members
aws rds describe-db-clusters \
  --db-cluster-identifier $(terraform output -raw cluster_id) \
  --query 'DBClusters[0].DBClusterMembers' \
  --output table
```

### View Autoscaling Activities

```bash
# Get recent scaling activities
aws application-autoscaling describe-scaling-activities \
  --service-namespace rds \
  --resource-id cluster:$(terraform output -raw cluster_id) \
  --max-results 20
```

**Output shows**:
- Timestamp of scaling activity
- Reason for scaling (e.g., "CPU above target")
- Old and new capacity
- Status (Successful, Failed, InProgress)

### CloudWatch Metrics

```bash
# CPU utilization over last hour
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBClusterIdentifier,Value=$(terraform output -raw cluster_id) \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# Database connections
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBClusterIdentifier,Value=$(terraform output -raw cluster_id) \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### Performance Insights

View query performance as replicas scale:

```bash
aws rds describe-db-cluster-performance-insights \
  --db-cluster-identifier $(terraform output -raw cluster_id)
```

## Testing Autoscaling

### 1. Generate CPU Load (Scale Out)

Connect to the database and run CPU-intensive queries:

```sql
-- Generate high CPU load
SELECT pg_sleep(0.1), count(*)
FROM generate_series(1, 10000000)
CROSS JOIN generate_series(1, 100);

-- Run in multiple parallel connections to exceed 70% CPU
```

**Expected**: Within 1-2 minutes, a new replica should be added.

### 2. Stop Load (Scale In)

```bash
# Kill all connections generating load
# Wait 5 minutes (scale_in_cooldown)
```

**Expected**: After cooldown, excess replicas are removed.

### 3. Test Scheduled Actions

```bash
# Manually trigger scheduled action (for testing)
aws application-autoscaling put-scheduled-action \
  --service-namespace rds \
  --resource-id cluster:$(terraform output -raw cluster_id) \
  --scheduled-action-name test-scale-up \
  --schedule "at($(date -u -d '+1 minute' +%Y-%m-%dT%H:%M:%S))" \
  --scalable-target-action MinCapacity=3,MaxCapacity=5
```

### 4. Monitor Scaling Activities

```bash
# Watch scaling in real-time
watch -n 10 'aws application-autoscaling describe-scaling-activities \
  --service-namespace rds \
  --resource-id cluster:$(terraform output -raw cluster_id) \
  --max-results 5'
```

## Cost Optimization

### Estimate Costs

**Example scenario**:
- Instance class: `db.r6g.large` ($0.29/hour)
- Business hours (8 AM-6 PM, Mon-Fri): 3 replicas
- Off-hours: 1 replica
- Writer instance: 1 (always on)

**Monthly cost calculation**:
```
Writer:           1 × 730 hours × $0.29 = $211.70
Business hours:   3 × 250 hours × $0.29 = $217.50
Off-hours:        1 × 480 hours × $0.29 = $139.20
Total:                                    $568.40/month
```

**Without autoscaling** (always 3 replicas):
```
Writer + 3 replicas: 4 × 730 hours × $0.29 = $846.80/month
Savings: $278.40/month (33%)
```

### Cost Optimization Tips

1. **Lower off-hours capacity**:
```hcl
off_hours_min_capacity = 0  # Scale to zero replicas at night
```

2. **Use smaller instance classes** for predictable workloads:
```hcl
instance_class = "db.t3.medium"  # $0.082/hour vs $0.29/hour
```

3. **Adjust target values** based on actual usage:
```hcl
cpu_target_value = 75  # Higher = fewer replicas, more cost-effective
```

4. **Tune cooldown periods** to avoid unnecessary scaling:
```hcl
scale_in_cooldown = 600   # Wait 10 minutes before scale-in
```

## Best Practices

### 1. Capacity Planning

- **Start conservative**: Begin with narrow min/max range (1-3)
- **Monitor first week**: Observe scaling patterns
- **Adjust gradually**: Increase max_capacity if hitting limits

### 2. Metric Selection

- **CPU**: Good for compute-heavy workloads
- **Connections**: Good for connection-pool-limited applications
- **Combine both**: Most robust approach

### 3. Cooldown Periods

- **Scale-out**: Short (60-120s) for fast response
- **Scale-in**: Long (300-600s) to avoid flapping
- **Connection-based**: Longer cooldowns (10+ minutes)

### 4. Scheduled Actions

- **Pre-scale**: Schedule scale-up 1-2 hours before peak
- **Timezone**: Use UTC and convert from local time
- **Overlap**: Later schedules override earlier ones

### 5. Monitoring

- **Set CloudWatch alarms** for autoscaling failures
- **Review weekly**: Check if targets need tuning
- **Cost tracking**: Monitor spend vs performance

## Troubleshooting

### Issue: Replicas not scaling out

**Check**:
```bash
# Verify autoscaling is enabled
aws application-autoscaling describe-scalable-targets \
  --service-namespace rds \
  --resource-id cluster:$(terraform output -raw cluster_id)
```

**Solution**:
- Ensure `autoscaling_enabled = true`
- Verify metrics exceed target values
- Check max_capacity not reached
- Review cooldown periods

### Issue: Too many scaling activities (flapping)

**Solution**:
- Increase cooldown periods
- Raise target values (less sensitive)
- Widen min/max capacity range
- Review if step scaling is too aggressive

### Issue: Scheduled action not triggering

**Check**:
```bash
# List scheduled actions
aws application-autoscaling describe-scheduled-actions \
  --service-namespace rds \
  --resource-id cluster:$(terraform output -raw cluster_id)
```

**Solution**:
- Verify cron expression syntax
- Check timezone setting
- Ensure scheduled action name is unique
- Review CloudWatch Events for errors

### Issue: Replicas added but performance still poor

**Analysis**:
- Check if workload is read-heavy (replicas help)
- vs write-heavy (replicas don't help)
- Review query performance in Performance Insights
- Consider vertical scaling (larger instance class)

## Cleanup

```bash
# Destroy all resources
terraform destroy
```

**Note**: Autoscaling will be disabled before cluster deletion.

## Related Examples

- [aurora-global-cluster](../aurora-global-cluster) - Multi-region disaster recovery
- [aurora-limitless](../aurora-limitless) - Horizontal scaling with Aurora Limitless
- [aurora-postgresql-advanced](../aurora-postgresql-advanced) - Advanced PostgreSQL features

## References

- [Aurora Autoscaling Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Integrating.AutoScaling.html)
- [Target Tracking Policies](https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-target-tracking.html)
- [Step Scaling Policies](https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-step-scaling-policies.html)
- [Scheduled Actions](https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-scheduled-scaling.html)
- [Aurora Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.BestPractices.html)
