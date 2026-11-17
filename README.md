# Terraform AWS RDS Module

A comprehensive, production-ready Terraform module for deploying AWS RDS instances and Aurora clusters with advanced features and best practices built-in.

## ✨ Features

### Core Capabilities

- ✅ **Aurora & RDS Support**: Aurora clusters (PostgreSQL/MySQL) and RDS instances
- ✅ **Aurora Limitless**: Horizontal scaling with a DB shard group (`aws_rds_shard_group`)
- ✅ **Global Clusters**: Multi-region disaster recovery with sub-second replication
- ✅ **Serverless v2**: Auto-scaling Aurora with ACU-based capacity
- ✅ **RDS Proxy**: Connection pooling and management
- ✅ **Advanced Autoscaling**: Target tracking, step scaling, and scheduled actions

### Security & Compliance

- ✅ **Secrets Manager Integration**: RDS-managed master passwords with optional scheduled rotation
- ✅ **Encryption**: Storage encryption enabled by default
- ✅ **IAM Authentication**: Database IAM authentication support
- ✅ **Activity Streams**: Database activity monitoring for compliance
- ✅ **Deletion Protection**: Enabled by default for production safety

### Performance & Monitoring

- ✅ **Performance Insights**: Extended retention (7-731 days)
- ✅ **Enhanced Monitoring**: Up to 1-second granularity
- ✅ **CloudWatch Logs**: Comprehensive log exports
- ✅ **Custom Parameter Groups**: Cluster and instance-level tuning

### High Availability

- ✅ **Multi-AZ Deployment**: Automatic failover support
- ✅ **Read Replicas**: Configurable instance count with promotion tiers
- ✅ **Backup & Restore**: Automated backups with configurable retention
- ✅ **Backtrack**: Rewind database to previous point (MySQL only)

### Database Engines

- ✅ **Aurora PostgreSQL**: 11.x, 12.x, 13.x, 14.x, 15.x, 16.x
- ✅ **Aurora MySQL**: 5.7, 8.0 (Aurora MySQL 2.x, 3.x)
- ✅ **RDS PostgreSQL**: 12.x, 13.x, 14.x, 15.x, 16.x
- ✅ **RDS MySQL**: 5.7, 8.0
- ✅ **RDS MariaDB**: 10.x

## 📁 Module Structure

The module is organized with numbered files for logical ordering:

```
rds/
├── 0-versions.tf          # Provider versions
├── 1-variables.tf         # Input variables (24 top-level variables, 14 of them deprecated no-ops)
├── 2-cluster.tf           # Aurora clusters, global clusters, shard groups, endpoints
├── 3-db-instances.tf      # Standard RDS instances, subnet groups, option groups
├── 3-instances.tf         # Aurora cluster instances
├── 4-parameter-groups.tf  # Parameter groups (cluster + instance)
├── 5-data.tf              # Data sources
├── 5-monitoring.tf        # CloudWatch log groups, monitoring IAM roles, activity streams, secret rotation
├── 6-autoscaling.tf       # Advanced autoscaling policies
├── 7-proxies.tf           # RDS Proxy configuration (Aurora + RDS)
├── 8-locals.tf            # Local values & data processing
└── 9-outputs.tf           # Outputs (75 outputs)
```

## 🚀 Quick Start

### Standard RDS PostgreSQL

```hcl
module "rds" {
  source = "github.com/jhonmezaa/terraform-aws-rds//rds?ref=v3.1.0"

  account_name = "prod"
  project_name = "myapp"

  instances = {
    primary = {
      engine         = "postgres"
      engine_version = "16.4"
      instance_class = "db.r6g.large"

      allocated_storage     = 100
      max_allocated_storage = 500
      storage_type          = "gp3"

      database_name               = "myapp_db"
      master_username             = "dbadmin"
      manage_master_user_password = true

      vpc_security_group_ids = [aws_security_group.db.id]
      subnet_ids             = module.vpc.database_subnets
      create_subnet_group    = true
      multi_az               = true

      storage_encrypted   = true
      deletion_protection = true

      performance_insights_enabled = true
      monitoring_interval          = 60
      create_monitoring_role       = true
    }

    # Read replica (references primary above)
    replica = {
      engine              = "postgres"
      engine_version      = "16.4"
      instance_class      = "db.r6g.large"
      replicate_source_db = "self:primary"
      storage_type        = "gp3"

      vpc_security_group_ids = [aws_security_group.db.id]

      performance_insights_enabled = true
      monitoring_interval          = 60
      create_monitoring_role       = true
    }
  }
}
```

> **Custom naming**: By default, identifiers follow the convention `{region_prefix}-rds-{account}-{project}-{key}`. You can customize this in two ways:
>
> 1. **Disable region prefix globally** with `use_region_prefix = false` (names become `rds-{account}-{project}-{key}`):
>
> ```hcl
> module "rds" {
>   source            = "github.com/jhonmezaa/terraform-aws-rds//rds?ref=v3.1.0"
>   use_region_prefix = false  # No region prefix in any resource name
>   # ...
> }
> ```
>
> 2. **Override a specific instance name** with the `identifier` field:
>
> ```hcl
> instances = {
>   legacy = {
>     identifier     = "my-custom-db-name"  # Fully custom name
>     engine         = "postgres"
>     instance_class = "db.r6g.large"
>     # ...
>   }
> }
> ```

### Aurora PostgreSQL Cluster

```hcl
module "aurora" {
  source = "github.com/jhonmezaa/terraform-aws-rds//rds?ref=v3.1.0"

  account_name = "prod"
  project_name = "myapp"

  clusters = {
    main = {
      # Engine
      engine         = "aurora-postgresql"
      engine_version = "15.4"
      engine_mode    = "provisioned"

      # Database
      database_name = "myapp_db"

      # Credentials (AWS Secrets Manager)
      master_username             = "dbadmin"
      manage_master_user_password = true

      # Network
      vpc_security_group_ids = [aws_security_group.aurora.id]
      subnet_ids             = module.vpc.database_subnets
      create_subnet_group    = true

      # Backup & HA
      backup_retention_period = 7
      deletion_protection     = true
      storage_encrypted       = true

      # Performance Insights
      performance_insights_enabled          = true
      performance_insights_retention_period = 7

      # Instances (1 writer + 2 readers)
      instances = {
        writer = {
          instance_class = "db.r6g.large"
          promotion_tier = 0
        }
        reader1 = {
          instance_class = "db.r6g.large"
          promotion_tier = 1
        }
        reader2 = {
          instance_class = "db.r6g.large"
          promotion_tier = 2
        }
      }
    }
  }
}
```

### Aurora Limitless (Horizontal Scaling)

```hcl
module "aurora_limitless" {
  source = "github.com/jhonmezaa/terraform-aws-rds//rds?ref=v3.1.0"

  account_name = "prod"
  project_name = "limitless"

  clusters = {
    limitless = {
      engine                   = "aurora-postgresql"
      engine_version           = "16.9-limitless" # Limitless engine versions end in -limitless
      storage_type             = "aurora-iopt1"
      cluster_scalability_type = "limitless"      # engine_mode is sent empty automatically

      # Limitless does not support RDS-managed passwords
      master_username             = "root"
      manage_master_user_password = false
      master_password             = var.db_password

      # Required by Limitless at cluster level
      cluster_monitoring_interval          = 30
      cluster_performance_insights_enabled = true

      # Shard Group (aws_rds_shard_group)
      shard_group = {
        enabled            = true
        max_acu            = 768
        compute_redundancy = 2 # High availability
      }

      # No instances: connect through the shard group endpoint (shard_group_endpoints output)
    }
  }
}
```

### Global Cluster (Multi-Region DR)

```hcl
# Primary Region
module "aurora_primary" {
  source = "github.com/jhonmezaa/terraform-aws-rds//rds?ref=v3.1.0"

  providers = {
    aws = aws.primary
  }

  account_name = "prod"
  project_name = "myapp"

  global_clusters = {
    main = {
      global_cluster_identifier = "myapp-global"
      engine                    = "aurora-postgresql"
      engine_version            = "15.4"
    }
  }

  clusters = {
    primary = {
      engine                        = "aurora-postgresql"
      engine_version                = "15.4"
      global_cluster_identifier      = "myapp-global"
      is_primary_cluster             = true
      enable_global_write_forwarding = false

      # Global databases do not support RDS-managed passwords
      master_username             = "dbadmin"
      manage_master_user_password = false
      master_password             = var.db_password

      # ... rest of configuration
    }
  }
}

# Secondary Region
module "aurora_secondary" {
  source = "github.com/jhonmezaa/terraform-aws-rds//rds?ref=v3.1.0"

  providers = {
    aws = aws.secondary
  }

  account_name = "prod"
  project_name = "myapp"

  clusters = {
    secondary = {
      engine                         = "aurora-postgresql"
      engine_version                 = "15.4"
      global_cluster_identifier      = "myapp-global"
      is_primary_cluster             = false # database_name and credentials are not sent
      enable_global_write_forwarding = true  # Forward writes to primary

      # ... rest of configuration
    }
  }

  depends_on = [module.aurora_primary]
}
```

### Advanced Autoscaling

```hcl
module "aurora_autoscaling" {
  source = "github.com/jhonmezaa/terraform-aws-rds//rds?ref=v3.1.0"

  clusters = {
    main = {
      # ... base configuration ...

      # Autoscaling Configuration
      autoscaling = {
        enabled      = true
        min_capacity = 1
        max_capacity = 5

        # Target Tracking Policies
        target_tracking_policies = {
          cpu = {
            target_metric      = "RDSReaderAverageCPUUtilization"
            target_value       = 70
            scale_in_cooldown  = 300
            scale_out_cooldown = 60
          }
          connections = {
            target_metric      = "RDSReaderAverageDatabaseConnections"
            target_value       = 500
            scale_in_cooldown  = 600
            scale_out_cooldown = 120
          }
        }

        # Scheduled Actions
        scheduled_actions = {
          business_hours_start = {
            schedule     = "cron(0 8 ? * MON-FRI *)"
            min_capacity = 3
            max_capacity = 10
          }
          business_hours_end = {
            schedule     = "cron(0 18 ? * MON-FRI *)"
            min_capacity = 1
            max_capacity = 3
          }
        }
      }
    }
  }
}
```

### RDS Proxy

```hcl
module "aurora_with_proxy" {
  source = "github.com/jhonmezaa/terraform-aws-rds//rds?ref=v3.1.0"

  clusters = {
    main = {
      # ... cluster configuration ...
    }
  }

  db_proxies = {
    main_proxy = {
      cluster_key    = "main"
      engine_family  = "POSTGRESQL"
      require_tls    = true
      idle_client_timeout = 1800

      auth = {
        auth_scheme = "SECRETS"
        secret_arn  = aws_secretsmanager_secret.db_credentials.arn
      }

      vpc_subnet_ids         = module.vpc.private_subnets
      vpc_security_group_ids = [aws_security_group.proxy.id]
    }
  }
}
```

## 📚 Examples

Complete, production-ready examples are available in the [examples](./examples) directory:

| Example                                                               | Description               | Features                                             |
| --------------------------------------------------------------------- | ------------------------- | ---------------------------------------------------- |
| [rds-postgresql](./examples/rds-postgresql)                           | Standard RDS PostgreSQL   | Multi-AZ, gp3 storage autoscaling, read replica      |
| [rds-mysql](./examples/rds-mysql)                                     | Standard RDS MySQL        | Multi-AZ, option group, audit plugin, Blue/Green     |
| [aurora-cluster](./examples/aurora-cluster)                           | Aurora MySQL cluster      | Writer + 2 readers, enhanced monitoring, autoscaling |
| [aurora-provisioned](./examples/aurora-provisioned)                   | Aurora PostgreSQL         | Provisioned instances, custom endpoints, autoscaling |
| [aurora-serverless-v2](./examples/aurora-serverless-v2)               | Aurora Serverless v2      | ACU-based scaling, writer + reader                   |
| [aurora-limitless](./examples/aurora-limitless)                       | Aurora Limitless Database | Shard group, cluster-level monitoring, no instances  |
| [aurora-global-cluster](./examples/aurora-global-cluster)             | Multi-region DR           | Cross-region replication, write forwarding, failover |
| [aurora-autoscaling-advanced](./examples/aurora-autoscaling-advanced) | Advanced Autoscaling      | Target tracking, step scaling, scheduled actions     |
| [aurora-mysql-advanced](./examples/aurora-mysql-advanced)             | MySQL Features            | Backtrack, binary logs, audit logging                |
| [aurora-postgresql-advanced](./examples/aurora-postgresql-advanced)   | PostgreSQL Features       | pgvector, PostGIS, logical replication, JSONB        |

Each example includes `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf` and a `README.md`; some also ship a `terraform.tfvars.example`.

## 📥 Variables

### Core Variables

| Name              | Description                                 | Type          | Default  |
| ----------------- | ------------------------------------------- | ------------- | -------- |
| account_name      | Account name for resource naming (1-32 chars, `^[a-z0-9-]+$`) | `string` | required |
| project_name      | Project name for resource naming (1-32 chars, `^[a-z0-9-]+$`) | `string` | required |
| create            | Master toggle: create all resources         | `bool`        | `true`   |
| tags_common       | Tags applied to every resource              | `map(string)` | `{}`     |
| use_region_prefix | Include region prefix in resource names     | `bool`        | `true`   |
| region_prefix     | Custom region prefix (auto-derived if null) | `string`      | `null`   |
| clusters          | Map of Aurora cluster configurations        | `map(object)` | `{}`     |
| instances         | Map of standard RDS instance configs        | `map(object)` | `{}`     |
| global_clusters   | Map of global cluster configurations        | `map(object)` | `{}`     |
| db_proxies        | Map of RDS Proxy configurations             | `map(object)` | `{}`     |

### Cluster Configuration

Each cluster in the `clusters` map supports 90+ configuration options. Key attributes:

| Name                                 | Description                                       | Type           | Default  |
| ------------------------------------ | ------------------------------------------------- | -------------- | -------- |
| engine                               | Database engine (aurora-postgresql, aurora-mysql) | `string`       | required |
| engine_version                       | Engine version                                    | `string`       | `null`   |
| database_name                        | Database name                                     | `string`       | `null`   |
| master_username                      | Master username                                   | `string`       | `null`   |
| manage_master_user_password          | Use Secrets Manager for passwords                 | `bool`         | `true`   |
| manage_master_user_password_rotation_automatically | Rotate the RDS-managed secret (needs a schedule) | `bool` | `false` |
| vpc_security_group_ids               | Security group IDs                                | `list(string)` | `[]`     |
| subnet_ids                           | Subnet IDs for DB subnet group (empty = use `db_subnet_group_name`) | `list(string)` | `[]` |
| instances                            | Map of instance configurations                    | `map(object)`  | `{}`     |
| cluster_scalability_type             | Set to "limitless" for Aurora Limitless           | `string`       | `"standard"` |
| shard_group                          | Limitless DB shard group (`enabled`, `max_acu`, `min_acu`, `compute_redundancy`) | `object` | `null` |
| global_cluster_identifier            | Global cluster ID for multi-region                | `string`       | `null`   |
| is_primary_cluster                   | `false` for secondary clusters of a global database | `bool`       | `true`   |
| cluster_monitoring_interval          | Enhanced Monitoring set on the cluster itself (Multi-AZ, Limitless) | `number` | `null` |
| autoscaling                          | Read replica autoscaling (`enabled`, capacities, target tracking, step scaling, scheduled actions) | `object` | `null` |
| skip_final_snapshot                  | Skip the final snapshot on destroy                | `bool`         | `true`   |
| backup_retention_period              | Backup retention days                             | `number`       | `7`      |
| deletion_protection                  | Enable deletion protection                        | `bool`         | `true`   |
| storage_encrypted                    | Enable encryption                                 | `bool`         | `true`   |
| performance_insights_enabled         | Enable Performance Insights                       | `bool`         | `false`  |

See [1-variables.tf](./rds/1-variables.tf) for the complete list of 90+ variables.

### Instance Configuration

Each instance in the `instances` map supports the following key attributes:

| Name                         | Description                                           | Type     | Default  |
| ---------------------------- | ----------------------------------------------------- | -------- | -------- |
| identifier                   | Custom RDS identifier (overrides auto-generated name) | `string` | `null`   |
| engine                       | Database engine (postgres, mysql, mariadb, etc.)      | `string` | required |
| engine_version               | Engine version                                        | `string` | `null`   |
| instance_class               | Instance class (db.r6g.large, db.t3.medium, etc.)     | `string` | required |
| allocated_storage            | Allocated storage in GB                               | `number` | `null`   |
| max_allocated_storage        | Max storage for autoscaling                           | `number` | `null`   |
| storage_type                 | Storage type (gp3, gp2, io1, io2)                     | `string` | `"gp3"`  |
| multi_az                     | Enable Multi-AZ deployment                            | `bool`   | `false`  |
| manage_master_user_password  | Use Secrets Manager for passwords                     | `bool`   | `true`   |
| replicate_source_db          | Source for read replica (ARN or "self:key")           | `string` | `null`   |
| parameter_group              | Custom parameter group configuration                  | `object` | `null`   |
| option_group                 | Option group configuration (RDS only, not Aurora)     | `object` | `null`   |
| deletion_protection          | Enable deletion protection                            | `bool`   | `true`   |
| storage_encrypted            | Enable encryption                                     | `bool`   | `true`   |
| performance_insights_enabled | Enable Performance Insights                           | `bool`   | `false`  |
| skip_final_snapshot          | Skip the final snapshot on destroy                    | `bool`   | `true`   |
| cloudwatch_log_class         | `STANDARD` or `INFREQUENT_ACCESS`                     | `string` | `"STANDARD"` |

### Deprecated variables

`enable_blue_green_deployments`, `blue_green_update_timeout`, `enable_cross_region_backups`,
`cross_region_backup_config`, `enable_query_editor`, `enable_encryption_in_transit`,
`tls_cipher_suites`, `enable_cost_optimization`, `cost_optimization_config`,
`enable_deletion_protection_override`, `audit_log_retention_days`, `enable_compliance_mode`,
`enable_experimental_features` and `experimental_config` were never wired to any resource.
They are kept for backward compatibility, are ignored and will be removed in the next major
version. Use the per-instance `blue_green_update` block for Blue/Green updates.

## 📤 Outputs

The module provides 75 outputs organized by resource type:

### Cluster Outputs

| Name                            | Description                 |
| ------------------------------- | --------------------------- |
| cluster_ids                     | Map of cluster identifiers  |
| cluster_arns                    | Map of cluster ARNs         |
| cluster_endpoints               | Map of writer endpoints     |
| cluster_reader_endpoints        | Map of reader endpoints     |
| cluster_ports                   | Map of cluster ports        |
| cluster_resource_ids            | Map of cluster resource IDs |
| cluster_hosted_zone_ids         | Map of hosted zone IDs      |
| cluster_master_user_secret_arns | Map of Secrets Manager ARNs |
| cluster_password_rotation_enabled | Map of managed-secret rotation flags |
| shard_group_arns / shard_group_endpoints / shard_group_resource_ids | Aurora Limitless DB shard group |

### Global Cluster Outputs

| Name                        | Description                        |
| --------------------------- | ---------------------------------- |
| global_cluster_ids          | Map of global cluster identifiers  |
| global_cluster_arns         | Map of global cluster ARNs         |
| global_cluster_resource_ids | Map of global cluster resource IDs |
| global_cluster_members      | Map of global cluster members      |

### Aurora Instance Outputs

| Name                       | Description                 |
| -------------------------- | --------------------------- |
| cluster_instance_ids       | Map of instance identifiers |
| cluster_instance_endpoints | Map of instance endpoints   |
| cluster_instance_arns      | Map of instance ARNs        |

### Standard RDS Instance Outputs

| Name                                | Description                             |
| ----------------------------------- | --------------------------------------- |
| db_instance_ids                     | Map of RDS instance identifiers         |
| db_instance_arns                    | Map of RDS instance ARNs                |
| db_instance_endpoints               | Map of RDS instance endpoints           |
| db_instance_addresses               | Map of RDS instance addresses           |
| db_instance_ports                   | Map of RDS instance ports               |
| db_instance_resource_ids            | Map of RDS instance resource IDs        |
| db_instance_status                  | Map of RDS instance statuses            |
| db_instance_master_user_secret_arns | Map of Secrets Manager ARNs             |
| db_instance_password_rotation_enabled | Map of managed-secret rotation flags  |
| db_instance_cloudwatch_log_group_names | Map of instance log group names      |
| db_instance_database_names          | Map of database names                   |
| db_option_group_ids                 | Map of option group identifiers         |
| db_option_group_arns                | Map of option group ARNs                |

### Autoscaling Outputs

| Name                                    | Description                        |
| --------------------------------------- | ---------------------------------- |
| autoscaling_target_ids                  | Map of autoscaling target IDs      |
| autoscaling_target_tracking_policy_arns | Map of target tracking policy ARNs |
| autoscaling_step_scaling_policy_arns    | Map of step scaling policy ARNs    |
| autoscaling_scheduled_action_names      | Map of scheduled action names      |

### RDS Proxy Outputs

| Name               | Description              |
| ------------------ | ------------------------ |
| db_proxy_ids       | Map of proxy identifiers |
| db_proxy_arns      | Map of proxy ARNs        |
| db_proxy_endpoints | Map of proxy endpoints   |
| db_proxy_names     | Map of proxy names       |

See [9-outputs.tf](./rds/9-outputs.tf) for the complete list of 75 outputs.

## 🔒 Security Best Practices

This module implements AWS security best practices:

### Encryption

- **Storage encryption**: Enabled by default
- **Encryption in transit**: SSL/TLS connections
- **KMS integration**: Support for customer-managed keys

### Access Control

- **IAM authentication**: Database IAM authentication support
- **Secrets Manager**: RDS-managed master passwords, optional rotation schedule (`manage_master_user_password_rotation_automatically`)
- **Security groups**: No default security groups created (bring your own)
- **Private access**: Public accessibility disabled by default

### Compliance

- **Activity Streams**: Database activity monitoring
- **Audit logging**: pgaudit (PostgreSQL), server_audit (MySQL)
- **CloudWatch Logs**: Comprehensive log exports
- **Deletion protection**: Enabled by default

### Backup & Recovery

- **Automated backups**: Configurable retention (7-35 days)
- **Final snapshots**: Disabled by default (`skip_final_snapshot = true`); set it to `false` in production. The generated identifier is `<name>-final-<random hex>`, stable across plans
- **Point-in-time recovery**: Up to backup retention period
- **Backtrack** (MySQL): Rewind database without restore

## 🎯 Aurora Limitless

Aurora Limitless enables horizontal scaling beyond single-node Aurora limits:

- **Shard group**: created with `aws_rds_shard_group` when `shard_group.enabled = true` (identifier `<cluster>-shard`)
- **Engine**: Aurora PostgreSQL `-limitless` engine versions; managed master passwords are not supported
- **Cluster-level monitoring**: set `cluster_monitoring_interval` and `cluster_performance_insights_enabled`
- **Use cases**: > 1M TPS, multi-tenant SaaS, massive analytics
- **Transparent**: No application code changes required

```hcl
clusters = {
  limitless = {
    engine                   = "aurora-postgresql"
    engine_version           = "16.9-limitless"
    cluster_scalability_type = "limitless"

    shard_group = {
      enabled            = true
      max_acu            = 768
      compute_redundancy = 2 # High availability
    }
  }
}
```

## 🌍 Global Clusters

Aurora Global Database provides multi-region disaster recovery:

- **Regions**: Up to 5 secondary regions
- **Replication lag**: < 1 second typical
- **RPO**: ~1 second
- **RTO**: ~1 minute (manual failover)
- **Write forwarding**: Forward writes from secondary to primary

```hcl
global_clusters = {
  main = {
    global_cluster_identifier = "myapp-global"
    engine                    = "aurora-postgresql"
    engine_version            = "15.4"
  }
}

clusters = {
  primary = {
    global_cluster_identifier      = "myapp-global"
    is_primary_cluster             = true
    enable_global_write_forwarding = false
  }
}
```

## 🔄 Autoscaling

Advanced autoscaling with multiple policy types:

### Target Tracking

Automatically adjust capacity to maintain target metrics:

- CPU utilization
- Database connections
- Custom CloudWatch metrics

### Step Scaling

Fine-grained control for extreme scenarios:

- Aggressive scale-out when CPU > 80%
- Conservative scale-in when CPU < 20%

### Scheduled Actions

Predictable capacity changes:

- Business hours (higher capacity)
- Off-hours (lower capacity)
- Weekend scaling

```hcl
autoscaling = {
  enabled      = true
  min_capacity = 1
  max_capacity = 5

  target_tracking_policies = {
    cpu = {
      target_metric      = "RDSReaderAverageCPUUtilization"
      target_value       = 70
      scale_in_cooldown  = 300
      scale_out_cooldown = 60
    }
  }

  scheduled_actions = {
    business_hours = {
      schedule     = "cron(0 8 ? * MON-FRI *)"
      min_capacity = 3
      max_capacity = 10
    }
  }
}
```

## 🔌 RDS Proxy

RDS Proxy provides connection pooling and management:

- **Connection pooling**: Reduce database connections
- **Failover time**: < 30 seconds vs ~60 seconds
- **IAM authentication**: Centralized credential management
- **Lambda integration**: Improved Lambda connection handling

```hcl
db_proxies = {
  main_proxy = {
    cluster_key         = "main"
    engine_family       = "POSTGRESQL"
    require_tls         = true
    idle_client_timeout = 1800

    auth = {
      auth_scheme = "SECRETS"
      secret_arn  = aws_secretsmanager_secret.db.arn
    }

    vpc_subnet_ids         = module.vpc.private_subnets
    vpc_security_group_ids = [aws_security_group.proxy.id]
  }
}
```

## 🛠️ Requirements

| Name      | Version  |
| --------- | -------- |
| terraform | >= 1.3   |
| aws       | >= 6.0   |
| random    | >= 3.1   |

## 🏗️ Architecture Patterns

### Multi-AZ High Availability

```
┌─────────────────────────────────────┐
│        Aurora Cluster (HA)          │
│                                     │
│  ┌────────────┐   ┌────────────┐    │
│  │ Writer     │   │ Reader 1   │    │
│  │ (AZ-a)     │──►│ (AZ-b)     │    │
│  └────────────┘   └────────────┘    │
│         │                           │
│         ▼                           │
│  ┌────────────┐                     │
│  │ Reader 2   │                     │
│  │ (AZ-c)     │                     │
│  └────────────┘                     │
└─────────────────────────────────────┘
```

### Multi-Region DR

```
┌──────────────────┐      ┌──────────────────┐
│  Primary Region  │      │ Secondary Region │
│   (us-east-1)    │◄────►│   (us-west-2)    │
│                  │      │                  │
│  Writer + Readers│ Repl │  Readers Only    │
│                  │ <1s  │  (Write Forward) │
└──────────────────┘      └──────────────────┘
```

## 📊 Monitoring & Observability

### CloudWatch Metrics

- CPU utilization
- Database connections
- Replication lag
- IOPS, throughput, latency

### Performance Insights

- Query-level performance data
- Top SQL statements
- Wait events analysis
- Database load

### CloudWatch Logs

- **PostgreSQL**: postgresql
- **MySQL**: audit, error, general, slowquery
- **Enhanced Monitoring**: OS-level metrics

## 💰 Cost Optimization

### Instance Sizing

- Start with r6g instances (Graviton2) for best price/performance
- Use t3/t4g for development/testing
- Monitor and right-size based on actual usage

### Autoscaling

- Scale down during off-hours
- Use scheduled actions for predictable patterns
- Monitor scaling activities and tune targets

### Storage

- Aurora storage scales automatically
- Only pay for data actually stored
- Backup storage beyond retention period billed separately

### Serverless v2

- Only pay for ACU consumed
- Scales to zero (0.5 ACU minimum)
- Ideal for variable/unpredictable workloads

## 🔧 Troubleshooting

### Common Issues

**Issue**: Cluster creation fails

- Verify subnets are in different AZs
- Check security group allows traffic
- Ensure engine version is supported

**Issue**: Cannot connect to database

- Verify security group rules
- Check publicly_accessible setting
- Confirm correct endpoint usage

**Issue**: High replication lag

- Monitor I/O capacity
- Check network connectivity
- Review write volume

**Issue**: Autoscaling not working

- Verify `autoscaling.enabled = true`
- Check target values and cooldowns
- Review CloudWatch metrics

See example READMEs for detailed troubleshooting guides.

## 📝 Changelog

See [CHANGELOG.md](./CHANGELOG.md) for version history and migration guides.

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

See [LICENSE](./LICENSE) file for details.

## 🆘 Support

For issues, questions, or feature requests:

- Open an issue in this repository
- Check existing issues and examples
- Review AWS RDS documentation
