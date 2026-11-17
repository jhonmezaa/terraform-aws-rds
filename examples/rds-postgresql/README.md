# Standard RDS PostgreSQL Example

Deploys a standard (non-Aurora) **RDS for PostgreSQL** primary instance and a
read replica with the `rds` module:

- Multi-AZ primary with gp3 storage and storage autoscaling
- Master password managed by RDS in Secrets Manager
- Performance Insights and Enhanced Monitoring (IAM roles created by the module)
- Custom DB parameter group
- Read replica declared in the same module with `replicate_source_db = "self:primary"`
- CloudWatch log exports with log groups created by the module

Generated names (us-east-1, defaults): `ause1-rds-mycompany-myapp-primary` and
`ause1-rds-mycompany-myapp-replica`.

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | ~> 1.3  |
| aws       | ~> 6.0  |

## Usage

```bash
terraform init
terraform plan -var 'vpc_security_group_ids=["sg-xxxx"]' -var 'database_subnet_ids=["subnet-a","subnet-b"]'
terraform apply
```

## Inputs

| Name                      | Description                                  | Type           | Default          |
| ------------------------- | -------------------------------------------- | -------------- | ---------------- |
| aws_region                | AWS region for resources                     | `string`       | `"us-east-1"`    |
| account_name              | Account name for resource naming             | `string`       | `"mycompany"`    |
| project_name              | Project name for resource naming             | `string`       | `"myapp"`        |
| engine_version            | PostgreSQL engine version                    | `string`       | `"16.4"`         |
| database_name             | Name of the database to create               | `string`       | `"app_db"`       |
| db_username               | Master username                              | `string`       | `"dbadmin"`      |
| instance_class            | Instance class of the primary                | `string`       | `"db.r6g.large"` |
| replica_instance_class    | Instance class of the read replica           | `string`       | `"db.r6g.large"` |
| replica_availability_zone | Availability zone of the read replica        | `string`       | `null`           |
| vpc_security_group_ids    | Security group IDs for the instances         | `list(string)` | n/a              |
| database_subnet_ids       | Subnet IDs for the DB subnet group (2+ AZs)  | `list(string)` | n/a              |

## Outputs

| Name             | Description                   |
| ---------------- | ----------------------------- |
| primary_endpoint | Primary RDS instance endpoint |
| primary_arn      | Primary RDS instance ARN      |
| replica_endpoint | Read replica endpoint         |
| primary_port     | Primary RDS instance port     |
| database_name    | Database name                 |
