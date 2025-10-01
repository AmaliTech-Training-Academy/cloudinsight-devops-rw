output "ebs_csi_driver_role_arn" {
  description = "ARN of the IAM role for the EBS CSI driver"
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "ebs_csi_driver_role_name" {
  description = "Name of the IAM role for the EBS CSI driver"
  value       = aws_iam_role.ebs_csi_driver.name
}

output "addon_name" {
  description = "Name of the EBS CSI driver addon"
  value       = aws_eks_addon.ebs_csi_driver.addon_name
}

output "addon_version" {
  description = "Version of the EBS CSI driver addon"
  value       = aws_eks_addon.ebs_csi_driver.addon_version
}

output "pod_identity_association_id" {
  description = "ID of the pod identity association for the EBS CSI driver"
  value       = aws_eks_pod_identity_association.ebs_csi_driver.association_id
}

output "service_account_name" {
  description = "Name of the service account for the EBS CSI driver"
  value       = var.service_account_name
}

output "namespace" {
  description = "Namespace where the EBS CSI driver is deployed"
  value       = var.namespace
}
