# =============================================================================
# Cluster Outputs
# =============================================================================

output "cluster_id" {
  description = "Aurora PostgreSQL cluster identifier"
  value       = module.aurora_postgresql.cluster_ids["postgresql"]
}

output "cluster_arn" {
  description = "Aurora PostgreSQL cluster ARN"
  value       = module.aurora_postgresql.cluster_arns["postgresql"]
}

output "cluster_endpoint" {
  description = "Aurora PostgreSQL cluster writer endpoint"
  value       = module.aurora_postgresql.cluster_endpoints["postgresql"]
}

output "cluster_reader_endpoint" {
  description = "Aurora PostgreSQL cluster reader endpoint"
  value       = module.aurora_postgresql.cluster_reader_endpoints["postgresql"]
}

output "cluster_port" {
  description = "Aurora PostgreSQL cluster port"
  value       = module.aurora_postgresql.cluster_ports["postgresql"]
}

output "cluster_resource_id" {
  description = "Aurora PostgreSQL cluster resource ID"
  value       = module.aurora_postgresql.cluster_resource_ids["postgresql"]
}

# =============================================================================
# Secrets Manager Outputs
# =============================================================================

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing master user credentials"
  value       = module.aurora_postgresql.cluster_master_user_secret_arns["postgresql"]
  sensitive   = true
}

# =============================================================================
# Instance Outputs
# =============================================================================

output "instance_ids" {
  description = "Map of instance identifiers"
  value       = module.aurora_postgresql.cluster_instance_ids
}

output "instance_endpoints" {
  description = "Map of instance endpoints"
  value       = module.aurora_postgresql.cluster_instance_endpoints
}

# =============================================================================
# Parameter Group Outputs
# =============================================================================

output "cluster_parameter_group_id" {
  description = "Cluster parameter group ID"
  value       = module.aurora_postgresql.cluster_parameter_group_ids["postgresql"]
}

output "db_parameter_group_ids" {
  description = "Map of DB parameter group IDs"
  value       = module.aurora_postgresql.db_parameter_group_ids
}

# =============================================================================
# Usage Instructions
# =============================================================================

output "connection_info" {
  description = "Connection information and PostgreSQL features"
  value       = <<-EOT

  ==========================================
  Aurora PostgreSQL Advanced Features!
  ==========================================

  Cluster Endpoint: ${module.aurora_postgresql.cluster_endpoints["postgresql"]}
  Reader Endpoint:  ${module.aurora_postgresql.cluster_reader_endpoints["postgresql"]}
  Port: ${module.aurora_postgresql.cluster_ports["postgresql"]}
  Database: ${var.database_name}

  HOW TO CONNECT:
  --------------------

  1. Retrieve the master password from Secrets Manager:

     aws secretsmanager get-secret-value \
       --secret-id ${module.aurora_postgresql.cluster_master_user_secret_arns["postgresql"]} \
       --query SecretString --output text | jq -r .password

  2. Connect using psql:

     psql -h ${module.aurora_postgresql.cluster_endpoints["postgresql"]} \
          -p ${module.aurora_postgresql.cluster_ports["postgresql"]} \
          -U ${var.db_username} \
          -d ${var.database_name}

  POSTGRESQL ADVANCED FEATURES:
  --------------------

  ✓ Logical Replication: Enabled (for CDC, event sourcing)
  ✓ Extensions: pg_stat_statements, pgaudit, auto_explain${var.enable_pgvector ? ", pgvector" : ""}${var.enable_postgis ? ", postgis" : ""}
  ✓ Performance Insights: ${var.performance_insights_retention_period} days retention
  ✓ Enhanced Monitoring: 60-second granularity
  ✓ Backup Retention: ${var.backup_retention_period} days
  ✓ Instances: 1 writer + 2 readers (Multi-AZ)

  ENABLE EXTENSIONS:
  --------------------

  -- Connect to database
  \c ${var.database_name}

  -- Enable pg_stat_statements (query performance tracking)
  CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

  ${var.enable_pgvector ? "-- Enable pgvector (vector similarity search for AI/ML)\nCREATE EXTENSION IF NOT EXISTS vector;\n" : ""}${var.enable_postgis ? "-- Enable PostGIS (geographic data)\nCREATE EXTENSION IF NOT EXISTS postgis;\nCREATE EXTENSION IF NOT EXISTS postgis_topology;\n" : ""}-- Enable other useful extensions
  CREATE EXTENSION IF NOT EXISTS hstore;       -- Key-value store
  CREATE EXTENSION IF NOT EXISTS pg_trgm;      -- Trigram matching for fuzzy search
  CREATE EXTENSION IF NOT EXISTS btree_gin;    -- GIN indexes for B-tree data
  CREATE EXTENSION IF NOT EXISTS btree_gist;   -- GiST indexes for B-tree data
  CREATE EXTENSION IF NOT EXISTS uuid-ossp;    -- UUID generation
  CREATE EXTENSION IF NOT EXISTS pgcrypto;     -- Cryptographic functions

  QUERY PERFORMANCE ANALYSIS:
  --------------------

  -- View slow queries (requires pg_stat_statements)
  SELECT
    query,
    calls,
    total_exec_time / 1000 AS total_time_seconds,
    mean_exec_time / 1000 AS mean_time_seconds,
    stddev_exec_time / 1000 AS stddev_time_seconds,
    rows
  FROM pg_stat_statements
  ORDER BY total_exec_time DESC
  LIMIT 20;

  -- Reset statistics
  SELECT pg_stat_statements_reset();

  -- View current queries
  SELECT pid, usename, application_name, state, query
  FROM pg_stat_activity
  WHERE state != 'idle'
  ORDER BY query_start;

  -- View table statistics
  SELECT schemaname, tablename, n_live_tup, n_dead_tup, last_autovacuum
  FROM pg_stat_user_tables
  ORDER BY n_live_tup DESC;

  -- View index usage
  SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
  FROM pg_stat_user_indexes
  ORDER BY idx_scan DESC;

  LOGICAL REPLICATION SETUP:
  --------------------

  -- Create publication (on writer)
  CREATE PUBLICATION my_publication FOR ALL TABLES;

  -- View publications
  SELECT * FROM pg_publication;

  -- Create replication slot
  SELECT * FROM pg_create_logical_replication_slot('my_slot', 'pgoutput');

  -- View replication slots
  SELECT * FROM pg_replication_slots;

  ${var.enable_pgvector ? "PGVECTOR EXAMPLES (AI/ML Vector Similarity):\n--------------------\n\n-- Create table with vector column\nCREATE TABLE embeddings (\n  id SERIAL PRIMARY KEY,\n  content TEXT,\n  embedding vector(1536)  -- OpenAI embeddings are 1536 dimensions\n);\n\n-- Create HNSW index for fast similarity search\nCREATE INDEX ON embeddings USING hnsw (embedding vector_cosine_ops);\n\n-- Insert embeddings\nINSERT INTO embeddings (content, embedding) VALUES\n  ('example text', '[...]'),  -- Insert your vector here\n  ('another text', '[...]');\n\n-- Find similar vectors (cosine similarity)\nSELECT content, embedding <=> '[query_vector]'::vector AS distance\nFROM embeddings\nORDER BY embedding <=> '[query_vector]'::vector\nLIMIT 10;\n\n" : ""}${var.enable_postgis ? "POSTGIS EXAMPLES (Geographic Data):\n--------------------\n\n-- Create table with geographic columns\nCREATE TABLE locations (\n  id SERIAL PRIMARY KEY,\n  name TEXT,\n  location geography(POINT, 4326)\n);\n\n-- Create spatial index\nCREATE INDEX ON locations USING GIST (location);\n\n-- Insert locations (longitude, latitude)\nINSERT INTO locations (name, location) VALUES\n  ('New York', ST_Point(-74.006, 40.7128)),\n  ('Los Angeles', ST_Point(-118.2437, 34.0522));\n\n-- Find locations within 100km of a point\nSELECT name,\n       ST_Distance(location, ST_Point(-73.935242, 40.730610)::geography) / 1000 AS distance_km\nFROM locations\nWHERE ST_DWithin(location, ST_Point(-73.935242, 40.730610)::geography, 100000)\nORDER BY distance_km;\n\n" : ""}FULL-TEXT SEARCH:
  --------------------

  -- Create table with full-text search
  CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title TEXT,
    body TEXT,
    search_vector tsvector
  );

  -- Create GIN index for full-text search
  CREATE INDEX ON documents USING GIN (search_vector);

  -- Update search vector automatically
  CREATE TRIGGER update_search_vector
    BEFORE INSERT OR UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION
    tsvector_update_trigger(search_vector, 'pg_catalog.english', title, body);

  -- Insert documents
  INSERT INTO documents (title, body) VALUES
    ('PostgreSQL Tutorial', 'Learn PostgreSQL database management'),
    ('Aurora Features', 'Amazon Aurora PostgreSQL advanced features');

  -- Search documents
  SELECT title, ts_rank(search_vector, query) AS rank
  FROM documents, to_tsquery('postgresql & aurora') AS query
  WHERE search_vector @@ query
  ORDER BY rank DESC;

  JSONB OPERATIONS:
  --------------------

  -- Create table with JSONB
  CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    data JSONB,
    created_at TIMESTAMP DEFAULT NOW()
  );

  -- Create GIN index on JSONB
  CREATE INDEX ON events USING GIN (data);

  -- Insert JSONB data
  INSERT INTO events (data) VALUES
    ('{"user_id": 123, "action": "login", "metadata": {"ip": "1.2.3.4"}}'),
    ('{"user_id": 456, "action": "purchase", "amount": 99.99}');

  -- Query JSONB
  SELECT * FROM events WHERE data @> '{"action": "login"}';
  SELECT data->>'user_id' AS user_id FROM events;
  SELECT data->'metadata'->>'ip' AS ip FROM events;

  CLOUDWATCH LOGS:
  --------------------

  # View PostgreSQL logs
  aws logs tail /aws/rds/cluster/${module.aurora_postgresql.cluster_ids["postgresql"]}/postgresql --follow

  # Filter for slow queries
  aws logs filter-log-events \
    --log-group-name /aws/rds/cluster/${module.aurora_postgresql.cluster_ids["postgresql"]}/postgresql \
    --filter-pattern "duration"

  PERFORMANCE INSIGHTS:
  --------------------

  # View Performance Insights
  aws rds describe-db-cluster-performance-insights \
    --db-cluster-identifier ${module.aurora_postgresql.cluster_ids["postgresql"]}

  USEFUL QUERIES:
  --------------------

  -- Database size
  SELECT pg_size_pretty(pg_database_size('${var.database_name}'));

  -- Table sizes
  SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
  FROM pg_tables
  WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

  -- Connection count
  SELECT count(*) FROM pg_stat_activity;

  -- Long-running queries
  SELECT pid, now() - query_start AS duration, query
  FROM pg_stat_activity
  WHERE state = 'active' AND query NOT LIKE '%pg_stat_activity%'
  ORDER BY duration DESC;

  -- Kill a query
  SELECT pg_terminate_backend(pid);

  ==========================================
  EOT
}
