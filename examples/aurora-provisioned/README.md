# Basic RDS Instance Example

This example creates a basic PostgreSQL RDS instance with the following features:

- PostgreSQL 15.4
- Multi-AZ deployment for high availability
- Encrypted storage
- 7-day backup retention
- Deletion protection enabled
- Custom subnet group

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Security Note

This example shows passing the password directly for demonstration purposes. In production, **always use AWS Secrets Manager**:

```hcl
db_secret_arn = aws_secretsmanager_secret.db_credentials.arn
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| db_password | Database password | string | yes |
| security_group_id | Security group ID for RDS | string | yes |
| subnet_ids | List of subnet IDs | list(string) | yes |

## Outputs

| Name | Description |
|------|-------------|
| db_endpoint | RDS instance endpoint |
| db_arn | RDS instance ARN |
