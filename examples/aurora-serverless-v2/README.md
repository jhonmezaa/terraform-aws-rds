# Aurora Serverless v2 Example

This example creates an Aurora PostgreSQL Serverless v2 cluster with automatic scaling.

## Features

- Aurora PostgreSQL Serverless v2
- Auto-scaling between 0.5 and 2.0 ACUs (Aurora Capacity Units)
- 2 instances across 2 availability zones
- Credentials stored in AWS Secrets Manager
- Encrypted storage
- Performance Insights enabled
- Cost-optimized for variable workloads

## Serverless v2 Benefits

Aurora Serverless v2 provides:

- **Instant scaling**: Scales database capacity instantly to match application demand
- **Fine-grained scaling**: Scales in increments as small as 0.5 ACUs
- **Cost efficiency**: Pay only for the database resources you consume
- **High availability**: Supports Multi-AZ deployments

## Scaling Configuration

This example scales between:
- **Min capacity**: 0.5 ACUs (~1 GB RAM)
- **Max capacity**: 2.0 ACUs (~4 GB RAM)

Adjust these values based on your workload requirements.

## Prerequisites

Create a secret in AWS Secrets Manager:

```json
{
  "username": "postgres",
  "password": "your-secure-password"
}
```

## Usage

```bash
terraform init
terraform plan -var="db_secret_arn=arn:aws:secretsmanager:..."
terraform apply
```

## Cost Optimization

For development/testing environments:
- Set lower min_capacity (e.g., 0.5)
- Set moderate max_capacity (e.g., 2.0)

For production:
- Set appropriate min_capacity for baseline load
- Set max_capacity with headroom for peak load

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| db_secret_arn | ARN of Secrets Manager secret | string | yes |
| security_group_id | Security group ID | string | yes |
| subnet_ids | List of subnet IDs | list(string) | yes |

## Outputs

| Name | Description |
|------|-------------|
| cluster_endpoint | Aurora Serverless v2 writer endpoint |
| cluster_reader_endpoint | Aurora Serverless v2 reader endpoint |
| cluster_arn | Aurora Serverless v2 cluster ARN |
