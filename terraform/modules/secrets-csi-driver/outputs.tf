# ========================================
# OUTPUTS FOR SECRETS CSI DRIVER MODULE
# ========================================

output "csi_driver_status" {
  description = "Information about the CSI drivers installed"
  value = {
    secrets_store_driver = {
      name      = helm_release.secrets_csi_driver.name
      namespace = helm_release.secrets_csi_driver.namespace
      version   = helm_release.secrets_csi_driver.version
      status    = helm_release.secrets_csi_driver.status
    }
    aws_provider = {
      name      = helm_release.secrets_csi_driver_aws_provider.name
      namespace = helm_release.secrets_csi_driver_aws_provider.namespace
      version   = helm_release.secrets_csi_driver_aws_provider.version
      status    = helm_release.secrets_csi_driver_aws_provider.status
    }
  }
}

output "verification_commands" {
  description = "Commands to verify CSI drivers are running"
  value       = <<-EOT
    # Verify CSI drivers are running
    kubectl get pods -n kube-system -l app=secrets-store-csi-driver
    kubectl get pods -n kube-system -l app=csi-secrets-store-provider-aws
    
    # Check CSI driver daemon sets
    kubectl get daemonset -n kube-system secrets-store-csi-driver
    kubectl get daemonset -n kube-system secrets-store-csi-driver-provider-aws
  EOT
}
