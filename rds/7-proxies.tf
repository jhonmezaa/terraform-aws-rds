# =============================================================================
# IAM Role for RDS Proxy
# =============================================================================

resource "aws_iam_role" "rds_proxy" {
  for_each = var.create ? var.db_proxies : {}

  name = "${local.region_prefix}-role-rds-proxy-${var.account_name}-${var.project_name}-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags_common,
    {
      Name = "${local.region_prefix}-role-rds-proxy-${var.account_name}-${var.project_name}-${each.key}"
    }
  )
}

# IAM Policy for Secrets Manager Access
resource "aws_iam_role_policy" "rds_proxy_secrets" {
  for_each = var.create ? var.db_proxies : {}

  name = "${local.region_prefix}-policy-rds-proxy-secrets-${var.account_name}-${var.project_name}-${each.key}"
  role = aws_iam_role.rds_proxy[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = each.value.auth.secret_arn != null ? [each.value.auth.secret_arn] : []
      }
    ]
  })
}

# =============================================================================
# RDS Proxy
# =============================================================================

resource "aws_db_proxy" "this" {
  for_each = var.create ? local.db_proxy_configs : {}

  name          = each.value.db_proxy_name
  engine_family = each.value.engine_family
  auth {
    auth_scheme               = each.value.auth.auth_scheme
    secret_arn                = each.value.auth.secret_arn
    iam_auth                  = each.value.auth.iam_auth
    client_password_auth_type = each.value.auth.client_password_auth_type
    description               = each.value.auth.description
  }

  role_arn               = each.value.role_arn
  vpc_subnet_ids         = each.value.vpc_subnet_ids
  vpc_security_group_ids = each.value.vpc_security_group_ids

  require_tls         = each.value.require_tls
  idle_client_timeout = each.value.idle_client_timeout

  debug_logging = each.value.debug_logging

  tags = merge(
    var.tags_common,
    each.value.tags,
    {
      Name = each.value.db_proxy_name
    }
  )

  depends_on = [
    aws_iam_role_policy.rds_proxy_secrets
  ]
}

# =============================================================================
# RDS Proxy Default Target Group
# =============================================================================

resource "aws_db_proxy_default_target_group" "this" {
  for_each = var.create ? local.db_proxy_configs : {}

  db_proxy_name = aws_db_proxy.this[each.value.proxy_key].name

  connection_pool_config {
    max_connections_percent      = each.value.max_connections_percent
    max_idle_connections_percent = each.value.max_idle_connections_percent
    connection_borrow_timeout    = each.value.connection_borrow_timeout
    session_pinning_filters      = each.value.session_pinning_filters
  }
}

# =============================================================================
# RDS Proxy Target (Cluster)
# =============================================================================

resource "aws_db_proxy_target" "this" {
  for_each = var.create ? local.db_proxy_configs : {}

  db_proxy_name         = aws_db_proxy.this[each.value.proxy_key].name
  target_group_name     = aws_db_proxy_default_target_group.this[each.value.proxy_key].name
  db_cluster_identifier = aws_rds_cluster.this[each.value.cluster_key].cluster_identifier
  # Note: target_arn is auto-configured based on db_cluster_identifier

  depends_on = [
    aws_db_proxy_default_target_group.this
  ]
}

# =============================================================================
# RDS Proxy Endpoint (Custom Endpoints)
# =============================================================================

# Note: aws_db_proxy_endpoint resource can be added here for custom proxy endpoints
# if needed for different use cases (e.g., separate read/write endpoints)
