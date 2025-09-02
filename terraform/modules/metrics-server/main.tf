resource "helm_release" "metrics_server" {
  name             = var.name
  repository       = var.repository
  chart            = "metrics-server"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = false

  values = [file("${path.module}/values/metrics-server-values.yaml")]

  timeout         = 300
  cleanup_on_fail = true
}

output "release_name" { value = helm_release.metrics_server.name }
output "namespace" { value = helm_release.metrics_server.namespace }
output "chart_version" { value = helm_release.metrics_server.version }
