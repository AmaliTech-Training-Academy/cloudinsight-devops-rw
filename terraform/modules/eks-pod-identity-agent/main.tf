resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = var.cluster_name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = var.addon_version
  resolve_conflicts_on_update = var.resolve_conflicts_on_update
  resolve_conflicts_on_create = var.resolve_conflicts_on_create
  tags                        = var.tags
}

output "addon_name" { value = aws_eks_addon.pod_identity_agent.addon_name }
output "addon_version" { value = aws_eks_addon.pod_identity_agent.addon_version }
