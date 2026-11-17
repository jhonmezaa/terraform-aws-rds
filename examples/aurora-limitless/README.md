# Aurora Limitless Database Example

This example deploys an **Aurora PostgreSQL Limitless Database**: a cluster with
`cluster_scalability_type = "limitless"` plus a **DB shard group**
(`aws_rds_shard_group`) that scales horizontally across shards.

## What it creates

- `aws_rds_cluster` with `cluster_scalability_type = "limitless"` (the module sends an empty `engine_mode`, as Limitless requires)
- `aws_rds_shard_group` (`<cluster>-shard`) with `max_acu`, `min_acu` and `compute_redundancy`
- Cluster-level Enhanced Monitoring (30 s) with the IAM role created by the module, and cluster-level Performance Insights (31 days), both required by Limitless
- DB subnet group and CloudWatch log group for the `postgresql` log export

The cluster has **no DB instances**: applications connect to the shard group
endpoint (`shard_group_endpoint` output).

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | ~> 1.3  |
| aws       | ~> 6.0  |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # set subnets, security groups...
export TF_VAR_db_password='a-strong-password'  # Limitless does not support managed passwords
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                   | Description                                         | Type           | Default             |
| ---------------------- | --------------------------------------------------- | -------------- | ------------------- |
| aws_region             | AWS region                                          | `string`       | `"us-east-1"`       |
| account_name           | Account name for resource naming                    | `string`       | `"dev"`             |
| project_name           | Project name for resource naming                    | `string`       | `"limitless-demo"`  |
| vpc_id                 | VPC ID (informational)                              | `string`       | n/a                 |
| database_subnet_ids    | Subnet IDs for the DB subnet group (2+ AZs)         | `list(string)` | n/a                 |
| vpc_security_group_ids | Security group IDs                                  | `list(string)` | n/a                 |
| db_username            | Master username                                     | `string`       | `"limitless_admin"` |
| db_password            | Master password (sensitive)                         | `string`       | n/a                 |
| engine_version         | Limitless engine version (ends in `-limitless`)     | `string`       | `"16.9-limitless"`  |
| max_acu                | Maximum capacity of the DB shard group (ACUs)       | `number`       | `1536`              |
| min_acu                | Minimum capacity of the DB shard group (ACUs)       | `number`       | `768`               |
| compute_redundancy     | Shard group compute redundancy (0, 1 or 2)          | `number`       | `2`                 |
| tags                   | Tags for all resources                              | `map(string)`  | see `variables.tf`  |

## Outputs

| Name                     | Description                             |
| ------------------------ | --------------------------------------- |
| cluster_id               | Aurora cluster identifier               |
| cluster_arn              | Aurora cluster ARN                      |
| cluster_endpoint         | Cluster writer endpoint                 |
| cluster_reader_endpoint  | Cluster reader endpoint                 |
| cluster_port             | Cluster port                            |
| cluster_scalability_type | `limitless`                             |
| shard_group_arn          | DB shard group ARN                      |
| shard_group_endpoint     | DB shard group endpoint (connect here)  |
| connection_info          | Connection instructions                 |

## Notes

- Limitless engine versions end in `-limitless` (for example `16.9-limitless`); check the versions available in your region with `aws rds describe-db-engine-versions --engine aurora-postgresql --query "DBEngineVersions[?contains(EngineVersion,'limitless')].EngineVersion"`.
- `storage_type = "aurora-iopt1"` (Aurora I/O-Optimized) is required by Limitless.
- `compute_redundancy = 2` creates two standby compute instances per shard (recommended for production); `0` disables them.
- Set `deletion_protection = true` and `skip_final_snapshot = false` for production.
- See the [AWS Limitless requirements](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/limitless-reqs-limits.html).
