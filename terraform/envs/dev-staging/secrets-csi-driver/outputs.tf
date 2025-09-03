# ========================================
# OUTPUTS FOR SECRETS CSI DRIVER - DEV STAGING
# ========================================

output "csi_driver_status" {
  description = "Status of the CSI drivers installed"
  value       = module.secrets_csi_driver.csi_driver_status
}

output "verification_commands" {
  description = "Commands to verify CSI drivers are running"
  value       = module.secrets_csi_driver.verification_commands
}
