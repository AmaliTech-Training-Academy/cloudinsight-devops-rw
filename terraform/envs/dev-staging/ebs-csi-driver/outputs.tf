output "ebs_csi_driver_role_arn" {
  description = "ARN of the IAM role for the EBS CSI driver"
  value       = module.ebs_csi_driver.ebs_csi_driver_role_arn
}

output "ebs_csi_driver_role_name" {
  description = "Name of the IAM role for the EBS CSI driver"
  value       = module.ebs_csi_driver.ebs_csi_driver_role_name
}

output "addon_name" {
  description = "Name of the EBS CSI driver addon"
  value       = module.ebs_csi_driver.addon_name
}

output "addon_version" {
  description = "Version of the EBS CSI driver addon"
  value       = module.ebs_csi_driver.addon_version
}

output "pod_identity_association_id" {
  description = "ID of the pod identity association for the EBS CSI driver"
  value       = module.ebs_csi_driver.pod_identity_association_id
}

output "service_account_name" {
  description = "Name of the service account for the EBS CSI driver"
  value       = module.ebs_csi_driver.service_account_name
}

output "namespace" {
  description = "Namespace where the EBS CSI driver is deployed"
  value       = module.ebs_csi_driver.namespace
}
