# Aurora Cluster Example

This example creates an Aurora PostgreSQL cluster with the following features:

- Aurora PostgreSQL 15.4
- 3 instances across 3 availability zones
- Credentials stored in AWS Secrets Manager
- Encrypted storage
- 14-day backup retention
- Deletion protection enabled
- Performance Insights enabled

## Prerequisites

Create a secret in AWS Secrets Manager with the following format:

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

## High Availability

This configuration creates 3 instances across 3 availability zones for maximum availability. The cluster provides:

- **Writer endpoint**: For write operations
- **Reader endpoint**: Load-balanced read operations across reader instances

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| db_secret_arn | ARN of Secrets Manager secret | string | yes |
| security_group_id | Security group ID | string | yes |
| subnet_ids | List of subnet IDs | list(string) | yes |

## Outputs

| Name | Description |
|------|-------------|
| cluster_endpoint | Aurora cluster writer endpoint |
| cluster_reader_endpoint | Aurora cluster reader endpoint |
| cluster_arn | Aurora cluster ARN |
| cluster_members | List of cluster member instances |
