output "cluster_endpoint" {
  description = "Aurora Serverless v2 cluster writer endpoint"
  value       = module.aurora_serverless.cluster_endpoints["serverlessv2"]
}

output "cluster_reader_endpoint" {
  description = "Aurora Serverless v2 cluster reader endpoint"
  value       = module.aurora_serverless.cluster_reader_endpoints["serverlessv2"]
}

output "cluster_arn" {
  description = "Aurora Serverless v2 cluster ARN"
  value       = module.aurora_serverless.cluster_arns["serverlessv2"]
}
