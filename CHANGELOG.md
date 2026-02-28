# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v3.0.1] - 2026-02-27

### Added

- Optional `identifier` field on `instances` variable to allow custom RDS instance names, overriding the auto-generated `{region_prefix}-rds-{account}-{project}-{key}` convention
- `use_region_prefix` boolean variable (default: `true`) to control whether the region prefix is included in resource names. When `false`, names omit the prefix (e.g., `rds-prod-myapp-primary` instead of `ause1-rds-prod-myapp-primary`)

## [v3.0.0] - 2026-02-27

### BREAKING CHANGES

#### `db_proxies` variable modified

- `cluster_key` changed from `string` (required) to `optional(string)` - existing configs that relied on implicit required-ness will still work, but the type signature changed
- Added `instance_key = optional(string)` for targeting standard RDS instances
- Added XOR validation: exactly one of `cluster_key` or `instance_key` must be provided

**Migration**: Existing `db_proxies` configs using `cluster_key` require no changes. If you want to target a standard RDS instance, use `instance_key` instead.

### Added

#### Standard RDS Instance Support

The module now supports **standard RDS instances** (`aws_db_instance`) alongside Aurora clusters. Users can deploy PostgreSQL, MySQL, MariaDB, Oracle, and SQL Server instances using the new `instances` variable.

```hcl
instances = {
  primary = {
    engine         = "postgres"
    engine_version = "16.4"
    instance_class = "db.r6g.large"

    allocated_storage     = 100
    max_allocated_storage = 500
    storage_type          = "gp3"

    master_username             = "dbadmin"
    manage_master_user_password = true

    vpc_security_group_ids = [aws_security_group.db.id]
    subnet_ids             = module.vpc.database_subnets
    create_subnet_group    = true
    multi_az               = true
  }
}
```

**Features**:

- 9 engine types: `postgres`, `mysql`, `mariadb`, `oracle-ee`, `oracle-se2`, `sqlserver-ee`, `sqlserver-se`, `sqlserver-ex`, `sqlserver-web`
- Storage autoscaling via `max_allocated_storage`
- gp3 storage with configurable IOPS and throughput
- Multi-AZ deployment
- Secrets Manager password management
- Performance Insights and Enhanced Monitoring
- CloudWatch Logs export
- Custom parameter groups
- Option groups (RDS-specific feature, not available in Aurora)
- Blue/Green deployments
- Point-in-time restore
- Domain (Active Directory) integration
- Character set configuration (Oracle)
- Custom IAM instance profiles
- CA certificate selection

#### Self-Referencing Read Replicas

Create read replicas that reference other instances within the same module using the `"self:"` prefix:

```hcl
instances = {
  primary = {
    engine         = "postgres"
    instance_class = "db.r6g.large"
    # ... primary config
  }
  replica = {
    engine              = "postgres"
    instance_class      = "db.r6g.large"
    replicate_source_db = "self:primary"  # References primary above
    # ... replica config
  }
}
```

#### RDS Proxy for Standard Instances

RDS Proxy now supports both Aurora clusters and standard RDS instances:

```hcl
db_proxies = {
  app_proxy = {
    instance_key  = "primary"  # Target a standard RDS instance
    engine_family = "POSTGRESQL"
    # ...
  }
}
```

#### New Outputs

Added 17 new outputs for standard RDS instances:

- `db_instance_ids`, `db_instance_arns`, `db_instance_endpoints`
- `db_instance_addresses`, `db_instance_ports`, `db_instance_hosted_zone_ids`
- `db_instance_resource_ids`, `db_instance_status`
- `db_instance_master_user_secret_arns` (sensitive)
- `db_instance_master_usernames` (sensitive)
- `db_instance_database_names`
- `db_instance_availability_zones`, `db_instance_engine_versions`
- `db_instance_subnet_group_names`
- `db_option_group_ids`, `db_option_group_arns`

#### New Examples

- **rds-postgresql**: Standard RDS PostgreSQL with Multi-AZ, storage autoscaling, Performance Insights, parameter group, and self-referencing read replica
- **rds-mysql**: Standard RDS MySQL with Multi-AZ, option group (MARIADB_AUDIT_PLUGIN), Blue/Green deployment, CloudWatch logs export

### Changed

- `clusters` variable now has `default = {}` (was required) - allows using only `instances` without providing empty `clusters`
- `allocated_storage` in `instances` changed from required to optional (read replicas inherit from source)

#### New Files

- `rds/3-db-instances.tf`: Standard RDS instance resources (`aws_db_instance.this`, `aws_db_instance.read_replica`, `aws_db_subnet_group.instances`, `aws_db_option_group.this`)

#### Modified Files

- `rds/1-variables.tf`: Added `instances` variable, modified `db_proxies` and `clusters`
- `rds/4-parameter-groups.tf`: Added `aws_db_parameter_group.instances`
- `rds/5-monitoring.tf`: Added CloudWatch log groups and IAM roles for instances
- `rds/7-proxies.tf`: Dual cluster/instance support in proxy target
- `rds/8-locals.tf`: Added 9 new locals for instance processing
- `rds/9-outputs.tf`: Added 17 new outputs for instances

## [v2.2.1] - 2026-02-27

### Changed

- Standardize Terraform `required_version` to `~> 1.0` across module and examples

## [v2.2.0] - 2026-02-27

### Changed

- Update AWS provider constraint to `~> 6.0` across module and examples

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-02-27

### Changed

#### Safety Default

- Changed `apply_immediately` default from `true` to `false`
- Changes now apply during the next maintenance window instead of immediately
- Prevents unplanned downtime in production environments
- Users can still override with `apply_immediately = true` per cluster

## [2.0.0] - 2025-12-20

### ⚠️ BREAKING CHANGES

#### Variable Structure Changed

The `databases` variable has been replaced with `clusters` for Aurora clusters. This provides better clarity and supports advanced features.

**Before (v1.x)**:

```hcl
databases = {
  mydb = {
    aurora         = true
    engine         = "aurora-postgresql"
    engine_version = "15.4"
    # ...
  }
}
```

**After (v2.0)**:

```hcl
clusters = {
  mydb = {
    engine         = "aurora-postgresql"
    engine_version = "15.4"
    # ...
  }
}
```

#### Security Groups Removed

The module no longer creates security groups. Users must provide security group IDs via `vpc_security_group_ids`.

**Before (v1.x)**:

```hcl
# Module created security groups automatically
create_security_group = true
```

**After (v2.0)**:

```hcl
# Bring your own security groups
vpc_security_group_ids = [aws_security_group.db.id]
```

**Migration**: Create security groups separately using the [terraform-aws-security-group](../terraform-aws-security-group) module or native Terraform resources.

#### File Structure Reorganized

Module files have been reorganized with numbered prefixes for logical ordering:

**Before (v1.x)**:

- `versions.tf`
- `variables.tf`
- `main.tf`
- `outputs.tf`
- `locals.tf`

**After (v2.0)**:

- `0-versions.tf`
- `1-variables.tf`
- `2-cluster.tf`
- `3-instances.tf`
- `4-parameter-groups.tf`
- `5-data.tf`
- `5-monitoring.tf`
- `6-autoscaling.tf`
- `7-proxies.tf`
- `8-locals.tf`
- `9-outputs.tf`

**Migration**: No action required - Terraform state remains compatible.

#### Output Names Changed

Some output names have been standardized:

| Old Output (v1.x)              | New Output (v2.0)          |
| ------------------------------ | -------------------------- |
| `rds_cluster_endpoints`        | `cluster_endpoints`        |
| `rds_cluster_reader_endpoints` | `cluster_reader_endpoints` |
| `rds_cluster_ids`              | `cluster_ids`              |
| `rds_cluster_arns`             | `cluster_arns`             |

**Migration**: Update your Terraform code to use the new output names.

### ✨ Added

#### Aurora Limitless Database

Support for Aurora Limitless Database with horizontal scaling beyond single-node limits.

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
      compute_redundancy = 2
    }
  }
}
```

**Features**:

- Horizontal scaling from 768 ACU (0.75 TB) to 3,145,728 ACU (3 PB)
- Automatic sharding and distributed query processing
- PostgreSQL 15.5+ only
- Transparent to applications

#### Global Clusters (Multi-Region DR)

Full support for Aurora Global Database with cross-region replication.

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

**Features**:

- Sub-second cross-region replication
- Up to 5 secondary regions
- Write forwarding from secondary to primary
- RPO ~1 second, RTO ~1 minute

#### Advanced Autoscaling

Comprehensive autoscaling support with multiple policy types.

```hcl
clusters = {
  main = {
    # Autoscaling configuration
    autoscaling = {
      enabled      = true
      min_capacity = 1
      max_capacity = 5

      # Target tracking policies
      target_tracking_policies = {
        cpu = {
          target_metric      = "RDSReaderAverageCPUUtilization"
          target_value       = 70
          scale_in_cooldown  = 300
          scale_out_cooldown = 60
          disable_scale_in   = false
        }
        connections = {
          target_metric      = "RDSReaderAverageDatabaseConnections"
          target_value       = 500
          scale_in_cooldown  = 600
          scale_out_cooldown = 120
          disable_scale_in   = false
        }
      }

      # Step scaling policies
      step_scaling_policies = {
        cpu_high = {
          adjustment_type         = "PercentChangeInCapacity"
          metric_aggregation_type = "Average"
          cooldown                = 60
          step_adjustments = [
            {
              scaling_adjustment          = 50
              metric_interval_lower_bound = 0
              metric_interval_upper_bound = 10
            },
            {
              scaling_adjustment          = 100
              metric_interval_lower_bound = 10
              metric_interval_upper_bound = null
            }
          ]
          alarm = {
            comparison_operator = "GreaterThanThreshold"
            evaluation_periods  = 2
            metric_name         = "CPUUtilization"
            namespace           = "AWS/RDS"
            period              = 60
            statistic           = "Average"
            threshold           = 80
          }
        }
      }

      # Scheduled actions
      scheduled_actions = {
        business_hours_start = {
          schedule     = "cron(0 8 ? * MON-FRI *)"
          min_capacity = 3
          max_capacity = 10
          timezone     = "UTC"
        }
        business_hours_end = {
          schedule     = "cron(0 18 ? * MON-FRI *)"
          min_capacity = 1
          max_capacity = 3
          timezone     = "UTC"
        }
      }
    }
  }
}
```

**Features**:

- Target tracking policies (CPU, connections)
- Step scaling for fine-grained control with CloudWatch alarms
- Scheduled actions for predictable patterns
- Multiple concurrent policies

#### RDS Proxy

Complete RDS Proxy support for connection pooling and management.

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

**Features**:

- Connection pooling to reduce database load
- Improved failover time (< 30 seconds)
- IAM authentication support
- Lambda integration optimizations

#### Enhanced Monitoring & Logging

Comprehensive monitoring and logging capabilities.

```hcl
clusters = {
  main = {
    # Performance Insights
    performance_insights_enabled          = true
    performance_insights_retention_period = 731  # Up to 2 years

    # Enhanced Monitoring
    monitoring_interval = 60  # 1-60 seconds
    monitoring_role_arn = "arn:aws:iam::..."

    # CloudWatch Logs
    enabled_cloudwatch_logs_exports = ["postgresql"]  # or ["audit", "error", "general", "slowquery"]

    # Activity Streams
    activity_stream_mode = "async"  # or "sync"
  }
}
```

**Features**:

- Performance Insights with extended retention (up to 731 days)
- Enhanced Monitoring with 1-60 second granularity
- CloudWatch Logs export for all engine types
- Activity Streams for compliance

#### Advanced Parameter Groups

Comprehensive parameter group support at both cluster and instance levels.

```hcl
clusters = {
  main = {
    # Cluster parameter group
    cluster_parameter_group = {
      family      = "aurora-postgresql14"
      description = "Custom cluster parameters"
      parameters = [
        {
          name         = "log_min_duration_statement"
          value        = "1000"
          apply_method = "immediate"
        },
        {
          name         = "max_connections"
          value        = "1000"
          apply_method = "pending-reboot"
        }
      ]
    }

    # DB instance parameter group
    db_parameter_group = {
      family      = "aurora-postgresql14"
      description = "Custom instance parameters"
      parameters = [
        {
          name         = "shared_buffers"
          value        = "{DBInstanceClassMemory/4/8192}"
          apply_method = "pending-reboot"
        }
      ]
    }
  }
}
```

#### Secrets Manager Integration

Improved Secrets Manager integration with automatic password management.

```hcl
clusters = {
  main = {
    master_username             = "dbadmin"
    manage_master_user_password = true  # RDS manages password in Secrets Manager
  }
}
```

**Features**:

- Automatic password generation
- Automatic password rotation
- No plaintext passwords in Terraform state

#### MySQL-Specific Features

Enhanced support for Aurora MySQL features.

```hcl
clusters = {
  mysql = {
    engine         = "aurora-mysql"
    engine_version = "8.0.mysql_aurora.3.05.2"

    # Backtrack (rewind database without restore)
    backtrack_window = 86400  # 24 hours in seconds

    # Binary log configuration
    cluster_parameter_group = {
      family      = "aurora-mysql8.0"
      description = "Custom MySQL cluster parameters"
      parameters = [
        {
          name         = "binlog_format"
          value        = "ROW"
          apply_method = "pending-reboot"
        },
        {
          name         = "slow_query_log"
          value        = "1"
          apply_method = "immediate"
        }
      ]
    }
  }
}
```

**Features**:

- Backtrack support (up to 72 hours)
- Binary log format configuration
- MySQL-specific CloudWatch logs (audit, error, general, slowquery)
- Server audit logging

#### PostgreSQL-Specific Features

Enhanced support for Aurora PostgreSQL features.

```hcl
clusters = {
  postgresql = {
    engine         = "aurora-postgresql"
    engine_version = "15.4"

    # PostgreSQL cluster parameters
    cluster_parameter_group = {
      family      = "aurora-postgresql14"
      description = "Custom PostgreSQL cluster parameters"
      parameters = [
        {
          name         = "rds.logical_replication"
          value        = "1"
          apply_method = "pending-reboot"
        },
        {
          name         = "shared_preload_libraries"
          value        = "pg_stat_statements,pgaudit,auto_explain"
          apply_method = "pending-reboot"
        },
        {
          name         = "log_min_duration_statement"
          value        = "1000"
          apply_method = "immediate"
        }
      ]
    }
  }
}
```

**Features**:

- Logical replication for CDC
- PostgreSQL extensions (pgvector, PostGIS, pg_stat_statements, pgaudit)
- Auto-explain for slow queries
- Advanced parameter tuning

#### New Examples

Eight comprehensive, production-ready examples:

1. **aurora-autoscaling-advanced**: Advanced autoscaling with target tracking, step scaling, and scheduled actions
2. **aurora-mysql-advanced**: MySQL-specific features (backtrack, binary logs, audit logging)
3. **aurora-postgresql-advanced**: PostgreSQL-specific features (extensions, logical replication, pgaudit)
4. **aurora-limitless**: Horizontal scaling with Aurora Limitless Database
5. **aurora-global-cluster**: Multi-region disaster recovery with write forwarding
6. **aurora-serverless-v2**: Auto-scaling Aurora with ACU-based capacity
7. **aurora-cluster**: Production-ready Aurora MySQL cluster with autoscaling
8. **aurora-provisioned**: Aurora PostgreSQL with custom endpoints and heterogeneous instances

Each example includes:

- Complete Terraform configuration
- Comprehensive variable definitions
- Validated outputs
- Deployment-ready code (`terraform validate` passes)

#### New Variables

Added 33+ new variables (from 60 to 90+ variables):

- `clusters`: Map of cluster configurations
- `global_clusters`: Map of global cluster configurations
- `db_proxies`: Map of RDS Proxy configurations
- `cluster_scalability_type`: Aurora Limitless configuration
- `shard_group`: Shard group settings for Limitless
- `global_cluster_identifier`: For multi-region clusters
- `enable_global_write_forwarding`: Write forwarding configuration
- `autoscaling_target_tracking_policies`: Target tracking policies
- `autoscaling_step_scaling_policies`: Step scaling policies
- `autoscaling_scheduled_actions`: Scheduled autoscaling
- `manage_master_user_password`: Automatic password management
- `backtrack_window`: MySQL backtrack configuration
- `performance_insights_retention_period`: Extended retention
- `activity_stream_mode`: Activity stream configuration
- And many more...

#### New Outputs

Added 25+ new outputs (from 28 to 53 outputs):

- `global_cluster_ids`, `global_cluster_arns`, `global_cluster_resource_ids`
- `cluster_scalability_types`: Map of scalability types
- `db_proxy_ids`, `db_proxy_arns`, `db_proxy_endpoints`
- `autoscaling_target_ids`, `autoscaling_target_tracking_policy_arns`
- `autoscaling_step_scaling_policy_arns`, `autoscaling_scheduled_action_arns`
- `cluster_master_user_secret_arns`: Secrets Manager ARNs
- `cluster_password_rotation_enabled`: Password rotation status
- And many more...

### 🔄 Changed

#### Module Organization

- Split monolithic `main.tf` into logical, numbered files
- Improved code organization and maintainability
- Clearer separation of concerns

#### Parameter Groups

- Enhanced parameter group support
- Separate cluster and instance parameters
- Better validation and error handling

#### Monitoring

- Consolidated monitoring configuration
- Improved IAM role management
- Better CloudWatch Logs integration

#### Documentation

- Completely rewritten README with:
  - Clear feature overview
  - Quick start examples
  - Comprehensive configuration reference
  - Architecture diagrams
  - Cost optimization guidance
  - Troubleshooting tips

### 🐛 Fixed

#### Critical Fixes

- **Fixed parameter groups structure bug**: Module was expecting `cluster_parameter_group` (object with family, description, parameters array) but documentation showed `cluster_parameters` (map). Updated all examples to use correct structure.

  ```hcl
  # BEFORE (incorrect - not working)
  cluster_parameters = {
    max_connections = { value = "1000", apply_method = "pending-reboot" }
  }

  # AFTER (correct)
  cluster_parameter_group = {
    family      = "aurora-postgresql14"
    description = "Custom parameters"
    parameters = [
      { name = "max_connections", value = "1000", apply_method = "pending-reboot" }
    ]
  }
  ```

- **Fixed autoscaling structure**: Corrected nested autoscaling configuration structure

  ```hcl
  # BEFORE (incorrect)
  autoscaling_enabled = true
  autoscaling_target_tracking_policies = { ... }

  # AFTER (correct)
  autoscaling = {
    enabled = true
    target_tracking_policies = { ... }
    step_scaling_policies = { ... }
    scheduled_actions = { ... }
  }
  ```

#### Module Improvements

- Fixed deprecated `managed_policy_arns` warning (use `aws_iam_role_policy_attachment` instead)
- Fixed CloudWatch Log Group configuration (removed unsupported `log_class` attribute)
- Fixed password rotation configuration (managed via Secrets Manager, not cluster attributes)
- Fixed Aurora Limitless configuration (use `cluster_scalability_type`, not separate shard_group resource)
- Fixed network_type conflicts in cluster instances
- Removed unused `database_insights_mode` variable (was defined but never used)
- Removed 17 unused locals from `8-locals.tf` (code cleanup, reduced from 491 to 301 lines)

#### Example Fixes

- **aurora-autoscaling-advanced**: Corrected autoscaling structure to nested object
- **aurora-mysql-advanced**: Fixed `cluster_parameters` → `cluster_parameter_group` and `instance_parameters` → `db_parameter_group`
- **aurora-postgresql-advanced**: Fixed `cluster_parameters` → `cluster_parameter_group` and `instance_parameters` → `db_parameter_group`
- **aurora-serverless-v2**: Fixed outputs to reference correct module name and cluster key
- **aurora-cluster**: Fixed outputs to reference correct module name and cluster key
- **aurora-provisioned**: Fixed outputs to reference Aurora cluster instead of RDS instance

All 8 examples now validate successfully with `terraform validate`.

### 🗑️ Removed

- Removed security group creation (users must provide security group IDs)
- Removed `databases` variable (replaced with `clusters`)
- Removed legacy RDS instance support (focus on Aurora clusters)
- Removed unused variables and locals

### 📚 Documentation

- Added comprehensive CHANGELOG.md
- Updated README.md with all new features
- Added 5 new example configurations with detailed READMEs
- Each example includes:
  - Architecture diagrams
  - Deployment instructions
  - Configuration examples
  - Monitoring guidance
  - Troubleshooting tips
  - Cost optimization advice

## Migration Guide: v1.x to v2.0

### Step 1: Update Variable Names

Replace `databases` with `clusters`:

```hcl
# Before (v1.x)
databases = {
  mydb = { ... }
}

# After (v2.0)
clusters = {
  mydb = { ... }
}
```

### Step 2: Create Security Groups

The module no longer creates security groups. Create them separately:

```hcl
# Create security group
module "db_security_group" {
  source = "../terraform-aws-security-group/security-group"

  account_name = "prod"
  project_name = "myapp"
  description  = "Database security group"
  vpc_id       = module.vpc.vpc_id

  ingress_rules = {
    postgres = {
      description = "PostgreSQL from application"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  egress_rules = {
    all = {
      description = "Allow all outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

# Reference in RDS module
clusters = {
  main = {
    vpc_security_group_ids = [module.db_security_group.security_group_id]
    # ...
  }
}
```

### Step 3: Update Output References

Update references to renamed outputs:

```hcl
# Before (v1.x)
output "db_endpoint" {
  value = module.rds.rds_cluster_endpoints["mydb"]
}

# After (v2.0)
output "db_endpoint" {
  value = module.rds.cluster_endpoints["mydb"]
}
```

### Step 4: Test and Validate

```bash
# Initialize new module version
terraform init -upgrade

# Review planned changes
terraform plan

# Apply changes
terraform apply
```

### Step 5: Update Documentation

Update any documentation or runbooks that reference the old variable names or outputs.

## [1.0.0] - Previous Version

Initial release with basic RDS and Aurora support.

---

For detailed information about specific features, see the [README.md](README.md) and [examples](examples/) directory.
