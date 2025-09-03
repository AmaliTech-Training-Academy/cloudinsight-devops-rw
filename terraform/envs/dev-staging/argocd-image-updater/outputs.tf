# ArgoCD Image Updater Outputs
output "image_updater_release_name" {
  description = "The name of the ArgoCD Image Updater Helm release"
  value       = module.argocd_image_updater.release_name
}

output "image_updater_namespace" {
  description = "The namespace where ArgoCD Image Updater is deployed"
  value       = module.argocd_image_updater.namespace
}

output "image_updater_chart_version" {
  description = "The version of the ArgoCD Image Updater Helm chart deployed"
  value       = module.argocd_image_updater.chart_version
}

output "image_updater_service_account" {
  description = "The service account used by ArgoCD Image Updater"
  value       = module.argocd_image_updater.service_account_name
}

output "image_updater_iam_role_arn" {
  description = "The ARN of the IAM role created for ArgoCD Image Updater"
  value       = aws_iam_role.argocd_image_updater.arn
}

output "image_updater_pod_identity_association" {
  description = "The EKS Pod Identity association for ArgoCD Image Updater"
  value = {
    association_arn = aws_eks_pod_identity_association.argocd_image_updater.association_arn
    association_id  = aws_eks_pod_identity_association.argocd_image_updater.association_id
  }
}

# ECR Configuration Information
output "ecr_registry_info" {
  description = "ECR registry information configured for Image Updater"
  value = {
    registry_url    = local.ecr_api_url
    registry_domain = local.ecr_registry
    region          = local.ecr_region
  }
}

# Application Configuration Guidance
output "application_annotation_examples" {
  description = "Example annotations for ArgoCD Applications to enable image updates"
  value = {
    basic_config = {
      "argocd-image-updater.argoproj.io/image-list"                = "app-image=${local.ecr_registry}/cloudinsight-user-service"
      "argocd-image-updater.argoproj.io/app-image.update-strategy" = "semver"
    }
    advanced_config = {
      "argocd-image-updater.argoproj.io/image-list"                = "app-image=${local.ecr_registry}/cloudinsight-user-service"
      "argocd-image-updater.argoproj.io/app-image.update-strategy" = "semver"
      "argocd-image-updater.argoproj.io/app-image.allow-tags"      = "regexp:^v[0-9]+\\.[0-9]+\\.[0-9]+$"
      "argocd-image-updater.argoproj.io/app-image.ignore-tags"     = "latest,dev"
    }
  }
}
