module "cert_manager" {
  source        = "../../../modules/cert-manager"
  cluster_name  = data.terraform_remote_state.eks.outputs.cluster_name
  region        = var.region
  namespace     = var.namespace
  release_name  = var.release_name
  chart_version = var.chart_version
  install_crds  = var.install_crds
  extra_set     = var.extra_set
}

# Future: could add issuers here (left to separate module/app layer)

output "release_name" { value = module.cert_manager.release_name }
output "namespace" { value = module.cert_manager.namespace }
output "chart_version" { value = module.cert_manager.chart_version }
