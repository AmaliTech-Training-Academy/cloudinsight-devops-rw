# ========================================
# SECRETS ACCESS IAM MODULE
# Creates IAM roles and policies for secrets access
# ========================================

# Data source to get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM Role for Pod Identity (replaces IRSA)
resource "aws_iam_role" "secrets_access" {
  name = "${var.cluster_name}-secrets-access"

  # Pod Identity assume role policy
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name      = "${var.cluster_name}-secrets-access"
    Purpose   = "EKS Pod Identity for Secrets Manager access"
    ManagedBy = "Terraform"
  })
}

# IAM Policy for accessing AWS Secrets Manager
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.cluster_name}-secrets-access"
  description = "Policy for accessing AWS Secrets Manager via Pod Identity"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.allowed_secret_patterns
      }
    ]
  })

  tags = merge(var.tags, {
    Name      = "${var.cluster_name}-secrets-access-policy"
    Purpose   = "Secrets Manager access for EKS pods"
    ManagedBy = "Terraform"
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "secrets_access" {
  policy_arn = aws_iam_policy.secrets_access.arn
  role       = aws_iam_role.secrets_access.name
}
