locals {
  # Convert extra_set map into list of set blocks via dynamic
  extra_set_list = [for k, v in var.extra_set : { name = k, value = v }]
}

resource "helm_release" "this" {
  name             = var.release_name
  repository       = var.repository
  chart            = "cert-manager"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  set {
    name  = "installCRDs"
    value = tostring(var.install_crds)
  }

  dynamic "set" {
    for_each = local.extra_set_list
    content {
      name  = set.value.name
      value = set.value.value
    }
  }
}

output "release_name" { value = helm_release.this.name }
output "namespace" { value = helm_release.this.namespace }
output "chart_version" { value = helm_release.this.version }
