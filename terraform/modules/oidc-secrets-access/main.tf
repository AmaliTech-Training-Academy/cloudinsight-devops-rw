# ========================================
# OIDC SECRETS ACCESS MODULE
# Creates OIDC provider and IAM roles for secrets access using IRSA
# ========================================

# Data source to get EKS cluster information
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

# =====================================
# OIDC Provider for IRSA
# =====================================

data "tls_certificate" "eks" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-eks-irsa"
  })
}

# =====================================
# IAM Role for Secrets Access
# =====================================

# IAM policy document for OIDC assume role
data "aws_iam_policy_document" "oidc_secrets_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = [for service in var.services : "system:serviceaccount:${service.namespace}:${service.service_account}"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

# IAM role for secrets access
resource "aws_iam_role" "oidc_secrets" {
  name               = "${var.cluster_name}-oidc-secrets-access"
  assume_role_policy = data.aws_iam_policy_document.oidc_secrets_assume.json

  tags = merge(var.tags, {
    Name    = "${var.cluster_name}-oidc-secrets-access"
    Purpose = "OIDC-based secrets access for microservices"
  })
}

# IAM policy for secrets access
resource "aws_iam_policy" "oidc_secrets" {
  name        = "${var.cluster_name}-oidc-secrets-access"
  description = "Policy for OIDC-based secrets access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secrets_arns
      }
    ]
  })

  tags = merge(var.tags, {
    Name    = "${var.cluster_name}-oidc-secrets-access"
    Purpose = "OIDC-based secrets access policy"
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "oidc_secrets" {
  policy_arn = aws_iam_policy.oidc_secrets.arn
  role       = aws_iam_role.oidc_secrets.name
}
