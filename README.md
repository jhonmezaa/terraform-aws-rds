# Terraform AWS RDS Module

A comprehensive, production-ready Terraform module for deploying AWS RDS instances and Aurora clusters with advanced features and best practices built-in.

## ✨ Features

### Core Capabilities

- ✅ **Aurora & RDS Support**: Aurora clusters (PostgreSQL/MySQL) and RDS instances
- ✅ **Aurora Limitless**: Horizontal scaling beyond single-node limits (PostgreSQL 15.5+)
- ✅ **Global Clusters**: Multi-region disaster recovery with sub-second replication
- ✅ **Serverless v2**: Auto-scaling Aurora with ACU-based capacity
- ✅ **RDS Proxy**: Connection pooling and management
- ✅ **Advanced Autoscaling**: Target tracking, step scaling, and scheduled actions

### Security & Compliance

- ✅ **Secrets Manager Integration**: Automatic password management
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
├── 1-variables.tf         # Input variables (90+ variables)
├── 2-cluster.tf           # Aurora clusters & global clusters
├── 3-instances.tf         # Cluster instances
├── 4-parameter-groups.tf  # Parameter groups
├── 5-data.tf              # Data sources
├── 5-monitoring.tf        # CloudWatch & IAM for monitoring
├── 6-autoscaling.tf       # Advanced autoscaling policies
├── 7-proxies.tf           # RDS Proxy configuration
├── 8-locals.tf            # Local values & data processing
└── 9-outputs.tf           # Outputs (53 outputs)
```

## 🚀 Quick Start

### Aurora PostgreSQL Cluster

```hcl
module "aurora" {
  source = "./rds"

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
  source = "./rds"

  account_name = "prod"
  project_name = "limitless"

  clusters = {
    limitless = {
      engine                   = "aurora-postgresql"
      engine_version           = "15.5"  # Required for Limitless
      cluster_scalability_type = "limitless"

      # Shard Group Configuration
      shard_group = {
        enabled            = true
        max_acu            = 1536  # 0.75 TB to 3 PB
        min_acu            = 768
        compute_redundancy = 2      # High availability
      }

      # ... rest of configuration
    }
  }
}
```

### Global Cluster (Multi-Region DR)

```hcl
# Primary Region
module "aurora_primary" {
  source = "./rds"

  providers = {
    aws = aws.primary
  }

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
      global_cluster_identifier     = "myapp-global"
      is_primary_cluster            = true
      enable_global_write_forwarding = false

      # ... rest of configuration
    }
  }
}

# Secondary Region
module "aurora_secondary" {
  source = "./rds"

  providers = {
    aws = aws.secondary
  }

  clusters = {
    secondary = {
      engine                         = "aurora-postgresql"
      engine_version                 = "15.4"
      global_cluster_identifier      = "myapp-global"
      is_primary_cluster             = false
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
  source = "./rds"

  clusters = {
    main = {
      # ... base configuration ...

      # Autoscaling Configuration
      autoscaling_enabled      = true
      autoscaling_min_capacity = 1
      autoscaling_max_capacity = 5

      # Target Tracking Policies
      autoscaling_target_tracking_policies = {
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
      autoscaling_scheduled_actions = {
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
```

### RDS Proxy

```hcl
module "aurora_with_proxy" {
  source = "./rds"

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
| [aurora-limitless](./examples/aurora-limitless)                       | Aurora Limitless Database | Horizontal scaling, ACU-based, 768 ACU to 3 PB       |
| [aurora-global-cluster](./examples/aurora-global-cluster)             | Multi-region DR           | Cross-region replication, write forwarding, failover |
| [aurora-autoscaling-advanced](./examples/aurora-autoscaling-advanced) | Advanced Autoscaling      | Target tracking, step scaling, scheduled actions     |
| [aurora-mysql-advanced](./examples/aurora-mysql-advanced)             | MySQL Features            | Backtrack, binary logs, audit logging                |
| [aurora-postgresql-advanced](./examples/aurora-postgresql-advanced)   | PostgreSQL Features       | pgvector, PostGIS, logical replication, JSONB        |

Each example includes:

- Complete Terraform configuration
- terraform.tfvars.example
- Comprehensive README with:
  - Architecture diagrams
  - Deployment instructions
  - Usage examples
  - Monitoring guidance
  - Troubleshooting tips

## 📥 Variables

### Core Variables

| Name            | Description                          | Type          | Required |
| --------------- | ------------------------------------ | ------------- | -------- |
| account_name    | Account name for resource naming     | `string`      | yes      |
| project_name    | Project name for resource naming     | `string`      | yes      |
| clusters        | Map of Aurora cluster configurations | `map(object)` | no       |
| global_clusters | Map of global cluster configurations | `map(object)` | no       |
| db_proxies      | Map of RDS Proxy configurations      | `map(object)` | no       |

### Cluster Configuration

Each cluster in the `clusters` map supports 90+ configuration options. Key attributes:

| Name                                 | Description                                       | Type           | Default  |
| ------------------------------------ | ------------------------------------------------- | -------------- | -------- |
| engine                               | Database engine (aurora-postgresql, aurora-mysql) | `string`       | required |
| engine_version                       | Engine version                                    | `string`       | required |
| database_name                        | Database name                                     | `string`       | `null`   |
| master_username                      | Master username                                   | `string`       | `null`   |
| manage_master_user_password          | Use Secrets Manager for passwords                 | `bool`         | `false`  |
| vpc_security_group_ids               | Security group IDs                                | `list(string)` | required |
| subnet_ids                           | Subnet IDs for DB subnet group                    | `list(string)` | required |
| instances                            | Map of instance configurations                    | `map(object)`  | `{}`     |
| cluster_scalability_type             | Set to "limitless" for Aurora Limitless           | `string`       | `null`   |
| global_cluster_identifier            | Global cluster ID for multi-region                | `string`       | `null`   |
| autoscaling_enabled                  | Enable autoscaling                                | `bool`         | `false`  |
| autoscaling_target_tracking_policies | Target tracking policies                          | `map(object)`  | `{}`     |
| backup_retention_period              | Backup retention days                             | `number`       | `7`      |
| deletion_protection                  | Enable deletion protection                        | `bool`         | `true`   |
| storage_encrypted                    | Enable encryption                                 | `bool`         | `true`   |
| performance_insights_enabled         | Enable Performance Insights                       | `bool`         | `false`  |

See [1-variables.tf](./rds/1-variables.tf) for the complete list of 90+ variables.

## 📤 Outputs

The module provides 53 outputs organized by resource type:

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

### Global Cluster Outputs

| Name                        | Description                        |
| --------------------------- | ---------------------------------- |
| global_cluster_ids          | Map of global cluster identifiers  |
| global_cluster_arns         | Map of global cluster ARNs         |
| global_cluster_resource_ids | Map of global cluster resource IDs |
| global_cluster_members      | Map of global cluster members      |

### Instance Outputs

| Name                       | Description                 |
| -------------------------- | --------------------------- |
| cluster_instance_ids       | Map of instance identifiers |
| cluster_instance_endpoints | Map of instance endpoints   |
| cluster_instance_arns      | Map of instance ARNs        |

### Autoscaling Outputs

| Name                                    | Description                        |
| --------------------------------------- | ---------------------------------- |
| autoscaling_target_ids                  | Map of autoscaling target IDs      |
| autoscaling_target_tracking_policy_arns | Map of target tracking policy ARNs |
| autoscaling_step_scaling_policy_arns    | Map of step scaling policy ARNs    |
| autoscaling_scheduled_action_arns       | Map of scheduled action ARNs       |

### RDS Proxy Outputs

| Name               | Description              |
| ------------------ | ------------------------ |
| db_proxy_ids       | Map of proxy identifiers |
| db_proxy_arns      | Map of proxy ARNs        |
| db_proxy_endpoints | Map of proxy endpoints   |
| db_proxy_names     | Map of proxy names       |

See [9-outputs.tf](./rds/9-outputs.tf) for the complete list of 53 outputs.

## 🔒 Security Best Practices

This module implements AWS security best practices:

### Encryption

- **Storage encryption**: Enabled by default
- **Encryption in transit**: SSL/TLS connections
- **KMS integration**: Support for customer-managed keys

### Access Control

- **IAM authentication**: Database IAM authentication support
- **Secrets Manager**: Automatic password rotation
- **Security groups**: No default security groups created (bring your own)
- **Private access**: Public accessibility disabled by default

### Compliance

- **Activity Streams**: Database activity monitoring
- **Audit logging**: pgaudit (PostgreSQL), server_audit (MySQL)
- **CloudWatch Logs**: Comprehensive log exports
- **Deletion protection**: Enabled by default

### Backup & Recovery

- **Automated backups**: Configurable retention (7-35 days)
- **Final snapshots**: Enabled by default
- **Point-in-time recovery**: Up to backup retention period
- **Backtrack** (MySQL): Rewind database without restore

## 🎯 Aurora Limitless

Aurora Limitless enables horizontal scaling beyond single-node Aurora limits:

- **Capacity**: 768 ACU (0.75 TB) to 3,145,728 ACU (3 PB)
- **Engine**: PostgreSQL 15.5+ only
- **Use cases**: > 1M TPS, multi-tenant SaaS, massive analytics
- **Transparent**: No application code changes required

```hcl
clusters = {
  limitless = {
    engine                   = "aurora-postgresql"
    engine_version           = "15.5"
    cluster_scalability_type = "limitless"

    shard_group = {
      enabled            = true
      max_acu            = 1536
      min_acu            = 768
      compute_redundancy = 2  # High availability
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
autoscaling_target_tracking_policies = {
  cpu = {
    target_metric      = "RDSReaderAverageCPUUtilization"
    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

autoscaling_scheduled_actions = {
  business_hours = {
    schedule     = "cron(0 8 ? * MON-FRI *)"
    min_capacity = 3
    max_capacity = 10
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
| terraform | >= 1.5.0 |
| aws       | >= 5.0   |

## 🏗️ Architecture Patterns

### Multi-AZ High Availability

```
┌─────────────────────────────────────┐
│        Aurora Cluster (HA)          │
│                                     │
│  ┌────────────┐   ┌────────────┐  │
│  │ Writer     │   │ Reader 1   │  │
│  │ (AZ-a)     │──►│ (AZ-b)     │  │
│  └────────────┘   └────────────┘  │
│         │                           │
│         ▼                           │
│  ┌────────────┐                    │
│  │ Reader 2   │                    │
│  │ (AZ-c)     │                    │
│  └────────────┘                    │
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

- Verify autoscaling_enabled = true
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
