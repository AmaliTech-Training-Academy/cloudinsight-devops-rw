locals {
  base_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "metrics-server"
    CostCenter  = "${var.project_name}-${var.environment}"
  }, var.tags)
}

module "metrics_server" {
  source     = "../../../modules/metrics-server"
  depends_on = [data.aws_eks_node_group.general]
}

output "metrics_server_release_name" { value = module.metrics_server.release_name }
output "metrics_server_namespace" { value = module.metrics_server.namespace }
output "metrics_server_chart_version" { value = module.metrics_server.chart_version }
