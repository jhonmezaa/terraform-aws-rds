# Standard RDS MySQL Example

Deploys a standard (non-Aurora) **RDS for MySQL** instance with the `rds` module:

- Multi-AZ instance with gp3 storage and storage autoscaling
- Master password managed by RDS in Secrets Manager
- Custom DB parameter group and option group (MariaDB Audit Plugin)
- CloudWatch log exports (`audit`, `error`, `general`, `slowquery`) with log groups created by the module
- Enhanced Monitoring (60 s) with the IAM role created by the module

Generated names (us-east-1, defaults): instance `ause1-rds-mycompany-myapp-main`,
subnet group `ause1-subnet-group-mycompany-myapp-main`.

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

| Name                   | Description                                            | Type           | Default          |
| ---------------------- | ------------------------------------------------------ | -------------- | ---------------- |
| aws_region             | AWS region for resources                               | `string`       | `"us-east-1"`    |
| account_name           | Account name for resource naming                       | `string`       | `"mycompany"`    |
| project_name           | Project name for resource naming                       | `string`       | `"myapp"`        |
| engine_version         | MySQL engine version                                   | `string`       | `"8.0.36"`       |
| database_name          | Name of the database to create                         | `string`       | `"app_db"`       |
| db_username            | Master username                                        | `string`       | `"dbadmin"`      |
| instance_class         | Instance class                                         | `string`       | `"db.r6g.large"` |
| vpc_security_group_ids | Security group IDs for the instance                    | `list(string)` | n/a              |
| database_subnet_ids    | Subnet IDs for the DB subnet group (2+ AZs)            | `list(string)` | n/a              |

## Outputs

| Name              | Description                 |
| ----------------- | --------------------------- |
| instance_endpoint | RDS MySQL instance endpoint |
| instance_arn      | RDS MySQL instance ARN      |
| instance_port     | RDS MySQL instance port     |
| database_name     | Database name               |
| option_group_id   | Option group ID             |
