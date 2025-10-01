locals {
  service_annotations = merge({
    "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
    "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = var.nlb_target_type
    "service.beta.kubernetes.io/aws-load-balancer-scheme"          = var.load_balancer_scheme
  }, var.service_annotations_extra)

  values_yaml = yamlencode({
    controller = {
      ingressClassResource = {
        name = var.release_name
      }
      service = {
        annotations = local.service_annotations
      }
      metrics = {
        enabled = var.metrics_enabled
        port    = var.metrics_port
        service = {
          annotations = {
            "prometheus.io/scrape" = "true"
            "prometheus.io/port"   = tostring(var.metrics_port)
            "prometheus.io/path"   = "/metrics"
          }
        }
      }
    }
  })
}

resource "helm_release" "this" {
  name             = var.release_name
  repository       = var.repository
  chart            = "ingress-nginx"
  version          = var.chart_version != "" ? var.chart_version : null
  namespace        = var.namespace
  create_namespace = true
  values           = [local.values_yaml]
}

output "release_name" { value = helm_release.this.name }
output "namespace" { value = helm_release.this.namespace }
output "chart_version" { value = helm_release.this.version }
output "metrics_enabled" { value = var.metrics_enabled }
output "metrics_port" { value = var.metrics_port }
output "metrics_path" { value = "/metrics" }
