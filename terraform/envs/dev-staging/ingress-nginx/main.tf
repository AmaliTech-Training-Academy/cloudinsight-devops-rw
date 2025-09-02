module "ingress_nginx" {
  source                    = "../../../modules/ingress-nginx"
  cluster_name              = data.terraform_remote_state.eks.outputs.cluster_name
  region                    = var.region
  namespace                 = var.namespace
  release_name              = var.release_name
  chart_version             = var.chart_version
  load_balancer_scheme      = var.load_balancer_scheme
  nlb_target_type           = var.nlb_target_type
  service_annotations_extra = var.service_annotations_extra
}

output "release_name" { value = module.ingress_nginx.release_name }
output "namespace" { value = module.ingress_nginx.namespace }
output "chart_version" { value = module.ingress_nginx.chart_version }
