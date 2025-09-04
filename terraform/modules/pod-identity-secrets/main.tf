# ========================================
# POD IDENTITY SECRETS MODULE
# Creates Pod Identity associations for microservices with service-specific IAM roles
# ========================================

# Create Pod Identity associations for all microservices
resource "aws_eks_pod_identity_association" "microservices" {
  for_each = {
    for svc in var.microservices : "${svc.namespace}-${svc.service_account}" => svc
  }

  cluster_name    = var.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = each.value.role_arn # Service-specific role ARN

  tags = merge(var.tags, {
    Service        = each.value.name
    Namespace      = each.value.namespace
    ServiceAccount = each.value.service_account
    Purpose        = "Secrets Manager access via Pod Identity"
    ManagedBy      = "Terraform"
  })
}
