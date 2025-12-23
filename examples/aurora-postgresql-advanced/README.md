# Aurora PostgreSQL Advanced Example

This example demonstrates **advanced Aurora PostgreSQL features** including popular extensions (pgvector, PostGIS), logical replication, full-text search, JSONB operations, and comprehensive performance tuning.

## What is Aurora PostgreSQL?

Aurora PostgreSQL is a PostgreSQL-compatible relational database built for the cloud, offering up to 3x the performance of standard PostgreSQL with the availability and durability of commercial databases at 1/10th the cost.

## Features Demonstrated

- ✅ **PostgreSQL Extensions**: pgvector, PostGIS, pg_stat_statements, pgaudit, auto_explain
- ✅ **Logical Replication**: CDC (Change Data Capture) and event sourcing support
- ✅ **Advanced Data Types**: JSONB, arrays, hstore, full-text search vectors
- ✅ **Performance Optimization**: Shared buffers, work_mem, effective_cache_size tuning
- ✅ **Query Performance Tracking**: pg_stat_statements, auto_explain integration
- ✅ **Audit Logging**: pgaudit for compliance and security
- ✅ **Enhanced Monitoring**: 60-second granularity + Performance Insights
- ✅ **Multi-AZ High Availability**: 1 writer + 2 readers across AZs

## Prerequisites

1. **VPC with at least 2 subnets** in different Availability Zones
2. **Security group** allowing PostgreSQL traffic (port 5432)
3. **Terraform >= 1.5.0**
4. **AWS Provider >= 5.0**

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│        Aurora PostgreSQL with Advanced Features & Extensions      │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  Writer Instance (AZ-a)                   │   │
│  │                    db.r6g.large                           │   │
│  │              Read/Write Operations                        │   │
│  └───────────────────────┬──────────────────────────────────┘   │
│                          │                                        │
│                          │ Replication                            │
│                          │                                        │
│            ┌─────────────┴─────────────┐                         │
│            │                           │                         │
│  ┌─────────▼──────────┐    ┌──────────▼────────┐               │
│  │ Reader 1 (AZ-a)    │    │ Reader 2 (AZ-b)   │               │
│  │   db.r6g.large     │    │   db.r6g.large    │               │
│  │   Read Operations  │    │   Read Operations │               │
│  └────────────────────┘    └───────────────────┘               │
│                                                                    │
│  Extensions & Features:                                            │
│  • pgvector: AI/ML vector similarity search                       │
│  • PostGIS: Geographic data and spatial queries                   │
│  • pg_stat_statements: Query performance tracking                 │
│  • pgaudit: Security audit logging                                │
│  • auto_explain: Automatic EXPLAIN for slow queries               │
│  • Logical Replication: CDC and event sourcing                    │
│  • JSONB: Flexible document storage                               │
│  • Full-text Search: Advanced text search capabilities            │
│                                                                    │
└──────────────────────────────────────────────────────────────────┘
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

### 3. Enable Extensions

```hcl
enable_pgvector = true  # Vector similarity search for AI/ML
enable_postgis  = true  # Geographic data support
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

**Deployment time**: ~12-15 minutes (3 instances).

## PostgreSQL Extensions

### Preloaded Extensions

These extensions are configured in `shared_preload_libraries` and loaded at server start:

#### 1. pg_stat_statements

Tracks execution statistics of all SQL statements.

```sql
-- Enable extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- View top 20 slowest queries
SELECT
  query,
  calls,
  total_exec_time / 1000 AS total_time_seconds,
  mean_exec_time / 1000 AS mean_time_seconds,
  rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Reset statistics
SELECT pg_stat_statements_reset();
```

#### 2. pgaudit

Provides detailed session and object audit logging.

```sql
-- Audit configuration (already set in parameters)
SHOW pgaudit.log;  -- Shows: ddl,role,read,write

-- Check audit logs in CloudWatch
aws logs tail /aws/rds/cluster/CLUSTER_ID/postgresql --follow
```

#### 3. auto_explain

Automatically logs execution plans for slow queries.

```sql
-- Configuration (already set in parameters)
SHOW auto_explain.log_min_duration;  -- 1000ms
SHOW auto_explain.log_analyze;       -- on

-- Slow query plans appear in CloudWatch logs automatically
```

### Vector Similarity Search (pgvector)

**Use Case**: AI/ML applications, semantic search, recommendations

```sql
-- Enable extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create table with vector embeddings
CREATE TABLE documents (
  id SERIAL PRIMARY KEY,
  content TEXT,
  embedding vector(1536)  -- OpenAI ada-002 embeddings
);

-- Create HNSW index for fast similarity search
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);

-- Insert embeddings (example with random vectors)
INSERT INTO documents (content, embedding) VALUES
  ('PostgreSQL tutorial', array_fill(random(), ARRAY[1536])::vector),
  ('Machine learning guide', array_fill(random(), ARRAY[1536])::vector);

-- Find similar documents (cosine similarity)
SELECT
  content,
  1 - (embedding <=> '[query_vector]'::vector) AS similarity
FROM documents
ORDER BY embedding <=> '[query_vector]'::vector
LIMIT 10;
```

**Distance Operators**:
- `<->`: Euclidean distance (L2)
- `<#>`: Negative inner product
- `<=>`: Cosine distance

### Geographic Data (PostGIS)

**Use Case**: Location-based services, mapping, spatial analysis

```sql
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Create table with geographic column
CREATE TABLE locations (
  id SERIAL PRIMARY KEY,
  name TEXT,
  location geography(POINT, 4326)  -- WGS84 coordinate system
);

-- Create spatial index
CREATE INDEX ON locations USING GIST (location);

-- Insert locations (longitude, latitude)
INSERT INTO locations (name, location) VALUES
  ('New York', ST_Point(-74.006, 40.7128)),
  ('Los Angeles', ST_Point(-118.2437, 34.0522)),
  ('Chicago', ST_Point(-87.6298, 41.8781));

-- Find locations within 100km of a point
SELECT
  name,
  ST_Distance(location, ST_Point(-73.935242, 40.730610)::geography) / 1000 AS distance_km
FROM locations
WHERE ST_DWithin(location, ST_Point(-73.935242, 40.730610)::geography, 100000)
ORDER BY distance_km;

-- Calculate distance between two points
SELECT ST_Distance(
  ST_Point(-74.006, 40.7128)::geography,  -- New York
  ST_Point(-118.2437, 34.0522)::geography  -- Los Angeles
) / 1000 AS distance_km;
```

### Additional Useful Extensions

```sql
-- Key-value store
CREATE EXTENSION IF NOT EXISTS hstore;

-- Trigram matching for fuzzy text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Cryptographic functions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- B-tree GIN indexes
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- B-tree GiST indexes
CREATE EXTENSION IF NOT EXISTS btree_gist;
```

## Logical Replication

**Use Case**: CDC (Change Data Capture), event sourcing, data pipelines

### Enable Logical Replication

Already configured via `rds_logical_replication = 1`.

### Create Publication (Source)

```sql
-- Create publication for all tables
CREATE PUBLICATION my_publication FOR ALL TABLES;

-- Or for specific tables
CREATE PUBLICATION my_publication FOR TABLE users, orders;

-- View publications
SELECT * FROM pg_publication;

-- View published tables
SELECT * FROM pg_publication_tables;
```

### Create Replication Slot

```sql
-- Create logical replication slot
SELECT * FROM pg_create_logical_replication_slot('my_slot', 'pgoutput');

-- View replication slots
SELECT * FROM pg_replication_slots;

-- Monitor replication lag
SELECT
  slot_name,
  confirmed_flush_lsn,
  pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn) AS lag_bytes
FROM pg_replication_slots;
```

### Create Subscription (Target)

On a different database/cluster:

```sql
CREATE SUBSCRIPTION my_subscription
CONNECTION 'host=source-endpoint port=5432 dbname=source_db user=replication_user password=xxx'
PUBLICATION my_publication;

-- View subscriptions
SELECT * FROM pg_subscription;

-- Monitor subscription status
SELECT * FROM pg_stat_subscription;
```

## Full-Text Search

### Setup

```sql
-- Create table with full-text search
CREATE TABLE articles (
  id SERIAL PRIMARY KEY,
  title TEXT,
  body TEXT,
  search_vector tsvector
);

-- Create GIN index
CREATE INDEX ON articles USING GIN (search_vector);

-- Auto-update search vector
CREATE TRIGGER update_search_vector
  BEFORE INSERT OR UPDATE ON articles
  FOR EACH ROW EXECUTE FUNCTION
  tsvector_update_trigger(search_vector, 'pg_catalog.english', title, body);
```

### Search Queries

```sql
-- Insert data
INSERT INTO articles (title, body) VALUES
  ('PostgreSQL Performance', 'Tips for optimizing PostgreSQL queries'),
  ('Aurora Features', 'Amazon Aurora PostgreSQL advanced features');

-- Simple search
SELECT title, ts_rank(search_vector, query) AS rank
FROM articles, to_tsquery('postgresql') AS query
WHERE search_vector @@ query
ORDER BY rank DESC;

-- Boolean search (AND, OR, NOT)
SELECT title, ts_rank(search_vector, query) AS rank
FROM articles, to_tsquery('postgresql & aurora') AS query
WHERE search_vector @@ query
ORDER BY rank DESC;

-- Phrase search
SELECT title, ts_rank(search_vector, phraseto_tsquery('aurora features')) AS rank
FROM articles
WHERE search_vector @@ phraseto_tsquery('aurora features')
ORDER BY rank DESC;

-- Fuzzy search with trigrams (requires pg_trgm)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

SELECT title, similarity(title, 'postgre') AS sim
FROM articles
WHERE title % 'postgre'  -- % is the similarity operator
ORDER BY sim DESC;
```

## JSONB Operations

### Create Table

```sql
CREATE TABLE events (
  id SERIAL PRIMARY KEY,
  data JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create GIN index on JSONB
CREATE INDEX ON events USING GIN (data);

-- Index specific JSONB path
CREATE INDEX ON events USING GIN ((data -> 'user'));
```

### Insert and Query

```sql
-- Insert JSONB data
INSERT INTO events (data) VALUES
  ('{"user_id": 123, "action": "login", "metadata": {"ip": "1.2.3.4", "device": "mobile"}}'),
  ('{"user_id": 456, "action": "purchase", "amount": 99.99, "items": [1, 2, 3]}');

-- Query with containment (@>)
SELECT * FROM events WHERE data @> '{"action": "login"}';

-- Extract values (->  returns JSONB, ->> returns text)
SELECT data->>'user_id' AS user_id, data->>'action' AS action FROM events;

-- Navigate nested JSON
SELECT data->'metadata'->>'ip' AS ip FROM events;

-- Query array elements
SELECT * FROM events WHERE data->'items' ? '1';  -- Contains value 1

-- Aggregate JSONB
SELECT jsonb_agg(data) FROM events;

-- Update JSONB field
UPDATE events SET data = jsonb_set(data, '{metadata,device}', '"desktop"')
WHERE data->>'user_id' = '123';
```

## Performance Monitoring

### Query Performance

```sql
-- Top queries by execution time
SELECT
  substring(query, 1, 50) AS query,
  calls,
  mean_exec_time,
  total_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Queries with high variance
SELECT
  substring(query, 1, 50) AS query,
  stddev_exec_time / mean_exec_time AS coefficient_of_variation
FROM pg_stat_statements
WHERE calls > 100
ORDER BY coefficient_of_variation DESC
LIMIT 20;
```

### Table Statistics

```sql
-- Table sizes
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
  pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Dead tuples (vacuum candidates)
SELECT
  schemaname,
  tablename,
  n_live_tup,
  n_dead_tup,
  round(100 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct,
  last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

### Index Usage

```sql
-- Unused indexes
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexrelid IS NOT NULL
ORDER BY pg_relation_size(indexrelid) DESC;

-- Index hit ratio (should be > 99%)
SELECT
  sum(idx_blks_hit) / NULLIF(sum(idx_blks_hit + idx_blks_read), 0) * 100 AS index_hit_ratio
FROM pg_statio_user_indexes;
```

### Connection and Activity

```sql
-- Current connections
SELECT
  datname,
  count(*) AS connections,
  count(*) FILTER (WHERE state = 'active') AS active,
  count(*) FILTER (WHERE state = 'idle') AS idle
FROM pg_stat_activity
GROUP BY datname;

-- Long-running queries
SELECT
  pid,
  now() - query_start AS duration,
  state,
  query
FROM pg_stat_activity
WHERE state != 'idle' AND query NOT LIKE '%pg_stat_activity%'
ORDER BY duration DESC;

-- Kill a query
SELECT pg_terminate_backend(12345);  -- Replace with actual PID
```

## CloudWatch Logs

### Access Logs

```bash
# Tail PostgreSQL logs
aws logs tail /aws/rds/cluster/$(terraform output -raw cluster_id)/postgresql --follow

# Filter for errors
aws logs filter-log-events \
  --log-group-name /aws/rds/cluster/$(terraform output -raw cluster_id)/postgresql \
  --filter-pattern "ERROR"

# Filter for slow queries
aws logs filter-log-events \
  --log-group-name /aws/rds/cluster/$(terraform output -raw cluster_id)/postgresql \
  --filter-pattern "duration"
```

### Log Analysis

Logs include:
- Connection/disconnection events
- Slow queries (> 1 second)
- DDL statements
- Auto-explain output for slow queries
- pgaudit records

## Connect to the Database

### 1. Retrieve Password

```bash
SECRET_ARN=$(terraform output -raw master_user_secret_arn)

aws secretsmanager get-secret-value \
  --secret-id $SECRET_ARN \
  --query SecretString --output text | jq -r .password
```

### 2. Connect with psql

```bash
ENDPOINT=$(terraform output -raw cluster_endpoint)
PORT=$(terraform output -raw cluster_port)

psql -h $ENDPOINT -p $PORT -U postgres -d postgres_advanced_db
```

### 3. Verify Configuration

```sql
-- Check version
SELECT version();

-- Check extensions
SELECT * FROM pg_available_extensions WHERE installed_version IS NOT NULL;

-- Check parameters
SHOW shared_preload_libraries;
SHOW rds.logical_replication;
SHOW log_min_duration_statement;
```

## Best Practices

### 1. Extension Selection

- **Always use**: pg_stat_statements (performance tracking)
- **Security/Compliance**: pgaudit
- **AI/ML applications**: pgvector
- **Geographic data**: PostGIS
- **Full-text search**: pg_trgm + tsvector
- **Flexible schema**: JSONB + hstore

### 2. Performance Tuning

- **shared_buffers**: 25% of RAM (auto-configured)
- **effective_cache_size**: 50% of RAM (planner hint)
- **work_mem**: Start at 16 MB, increase for complex queries
- **maintenance_work_mem**: 512 MB minimum for large tables
- **random_page_cost**: 1.1 for SSD (default 4 is for spinning disks)

### 3. Monitoring

- **Enable Performance Insights**: Query-level analysis
- **pg_stat_statements**: Track all query performance
- **auto_explain**: Automatic EXPLAIN for slow queries
- **CloudWatch Alarms**: CPU, connections, replication lag

### 4. Indexing Strategy

- **B-tree**: Default for most cases
- **GIN**: JSONB, arrays, full-text search
- **GiST**: Geographic data (PostGIS)
- **HNSW**: Vector similarity (pgvector)

### 5. VACUUM and Maintenance

```sql
-- Manual VACUUM
VACUUM ANALYZE tablename;

-- Check autovacuum status
SELECT * FROM pg_stat_progress_vacuum;

-- Tune autovacuum (if needed)
ALTER TABLE tablename SET (autovacuum_vacuum_scale_factor = 0.1);
```

## Cost Optimization

### Instance Sizing

```hcl
# Production
instance_class = "db.r6g.large"  # $0.29/hour × 3 instances = $639/month

# Development
instance_class = "db.t3.medium"  # $0.082/hour × 3 instances = $180/month
```

### Storage

- Aurora storage scales automatically (1 GB to 128 TB)
- Billed per GB-month actually used
- Backup storage beyond retention period billed separately

### Performance Insights

- 7 days retention: Free
- 731 days retention: Additional cost

## Troubleshooting

### Issue: Cannot create extension

**Error**: `ERROR: could not open extension control file`

**Solution**: Verify extension is available:
```sql
SELECT * FROM pg_available_extensions WHERE name = 'pgvector';
```

If not available, check Aurora version compatibility.

### Issue: Slow queries not appearing in pg_stat_statements

**Solution**: Verify configuration:
```sql
SHOW shared_preload_libraries;  -- Should include pg_stat_statements
SELECT * FROM pg_stat_statements LIMIT 1;  -- Test if working
```

### Issue: Logical replication slot growing

**Solution**: Monitor and manage slots:
```sql
-- Check slot lag
SELECT
  slot_name,
  pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn) / 1024 / 1024 AS lag_mb
FROM pg_replication_slots;

-- Drop unused slot
SELECT pg_drop_replication_slot('my_slot');
```

## Cleanup

```bash
terraform destroy
```

**Important**: Set `deletion_protection = false` before destroying.

## Related Examples

- [aurora-mysql-advanced](../aurora-mysql-advanced) - Advanced MySQL features
- [aurora-autoscaling-advanced](../aurora-autoscaling-advanced) - Advanced autoscaling
- [aurora-global-cluster](../aurora-global-cluster) - Multi-region DR
- [aurora-limitless](../aurora-limitless) - Horizontal scaling

## References

- [Aurora PostgreSQL Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.AuroraPostgreSQL.html)
- [pgvector Documentation](https://github.com/pgvector/pgvector)
- [PostGIS Documentation](https://postgis.net/documentation/)
- [PostgreSQL Performance Tuning](https://www.postgresql.org/docs/current/performance-tips.html)
- [Aurora Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.BestPractices.html)
