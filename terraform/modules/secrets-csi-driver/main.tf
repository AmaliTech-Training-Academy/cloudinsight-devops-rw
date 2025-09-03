# ========================================
# SECRETS STORE CSI DRIVER MODULE
# Installs cluster-wide CSI driver components
# ========================================

# Install Secrets Store CSI Driver
resource "helm_release" "secrets_csi_driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  version    = var.csi_driver_version

  set {
    name  = "syncSecret.enabled"
    value = var.sync_secret_enabled
  }

  set {
    name  = "enableSecretRotation"
    value = var.enable_secret_rotation
  }

  set {
    name  = "rotationPollInterval"
    value = var.rotation_poll_interval
  }

  timeout = 300
}

# Install AWS Secrets Manager CSI Provider
resource "helm_release" "secrets_csi_driver_aws_provider" {
  name       = "secrets-store-csi-driver-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  version    = var.aws_provider_version

  timeout = 300

  depends_on = [helm_release.secrets_csi_driver]
}
