module "pod_identity_agent" {
  source        = "../../../modules/eks-pod-identity-agent"
  cluster_name  = data.terraform_remote_state.eks.outputs.cluster_name
  addon_version = var.addon_version
  tags          = local.base_tags
}

output "pod_identity_agent_addon_name" { value = module.pod_identity_agent.addon_name }
output "pod_identity_agent_addon_version" { value = module.pod_identity_agent.addon_version }
