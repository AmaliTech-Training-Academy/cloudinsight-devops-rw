# ========================================
# SECRETS ACCESS IAM MODULE
# Creates IAM roles for microservices to access AWS Secrets Manager
# Each service gets its own role with access only to its specific secrets
# ========================================

# Data source for current AWS account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create IAM role for each service
resource "aws_iam_role" "secrets_access" {
  for_each = {
    for svc in var.services : svc.name => svc
  }

  name = "eks-${var.cluster_name}-${each.value.name}-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnEquals = {
            "aws:SourceArn" = "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "eks-${var.cluster_name}-${each.value.name}-secrets-role"
    Service     = each.value.name
    ClusterName = var.cluster_name
    Purpose     = "Secrets Manager access for ${each.value.name}"
    ManagedBy   = "Terraform"
  })
}

# Create IAM policy for each service with access to their specific secrets
resource "aws_iam_policy" "secrets_access" {
  for_each = {
    for svc in var.services : svc.name => svc
  }

  name        = "eks-${var.cluster_name}-${each.value.name}-secrets-policy"
  description = "Policy for ${each.value.name} to access specific secrets in AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${each.value.secret_name}*"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "eks-${var.cluster_name}-${each.value.name}-secrets-policy"
    Service     = each.value.name
    ClusterName = var.cluster_name
    Purpose     = "Secrets access policy for ${each.value.name}"
    ManagedBy   = "Terraform"
  })
}

# Attach policy to role for each service
resource "aws_iam_role_policy_attachment" "secrets_access" {
  for_each = {
    for svc in var.services : svc.name => svc
  }

  role       = aws_iam_role.secrets_access[each.key].name
  policy_arn = aws_iam_policy.secrets_access[each.key].arn
}
