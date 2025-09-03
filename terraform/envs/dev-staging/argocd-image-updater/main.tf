# Remote state to read EKS outputs
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket  = "cloudinsight-tfstate"
    key     = "dev-staging/eks.tfstate"
    region  = var.region
    encrypt = true
  }
}

# Remote state to read ECR outputs
data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = {
    bucket  = "cloudinsight-tfstate"
    key     = "dev-staging/ecr.tfstate"
    region  = var.region
    encrypt = true
  }
}

# Remote state to read ArgoCD outputs
data "terraform_remote_state" "argocd" {
  backend = "s3"
  config = {
    bucket  = "cloudinsight-tfstate"
    key     = "dev-staging/argocd.tfstate"
    region  = var.region
    encrypt = true
  }
}

# Extract ECR registry URL from any repository URL
locals {
  # Get the first ECR repository URL and extract the registry domain
  sample_ecr_url = values(data.terraform_remote_state.ecr.outputs.ecr_repository_urls)[0]
  ecr_registry   = regex("^([^/]+)", local.sample_ecr_url)[0]
  ecr_region     = regex("dkr\\.ecr\\.([^.]+)", local.ecr_registry)[0]

  # ECR API URL
  ecr_api_url = "https://${local.ecr_registry}"
}

# IAM role for ArgoCD Image Updater with ECR permissions
data "aws_iam_policy_document" "argocd_image_updater_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "argocd_image_updater" {
  name               = "${data.terraform_remote_state.eks.outputs.cluster_name}-argocd-image-updater"
  assume_role_policy = data.aws_iam_policy_document.argocd_image_updater_assume_role.json

  tags = var.tags
}

# Attach ECR read-only policy to the role (includes GetAuthorizationToken)
resource "aws_iam_role_policy_attachment" "argocd_image_updater_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.argocd_image_updater.name
}

# EKS Pod Identity Association for ArgoCD Image Updater
resource "aws_eks_pod_identity_association" "argocd_image_updater" {
  cluster_name    = data.terraform_remote_state.eks.outputs.cluster_name
  namespace       = var.namespace
  service_account = var.service_account_name
  role_arn        = aws_iam_role.argocd_image_updater.arn

  tags = var.tags
}

# Deploy ArgoCD Image Updater
module "argocd_image_updater" {
  source = "../../../modules/argocd-image-updater"

  # Basic configuration
  release_name     = var.release_name
  chart_version    = var.chart_version
  namespace        = var.namespace
  create_namespace = false # ArgoCD namespace already exists

  # Service account
  service_account_name = var.service_account_name

  # Registry configuration for ECR
  registries = [
    {
      name        = "ECR"
      api_url     = local.ecr_api_url
      prefix      = local.ecr_registry
      ping        = true
      insecure    = false
      credentials = "ext:/scripts/auth.sh"
      credsexpire = "10h"
    }
  ]

  # Auth script for ECR authentication
  auth_scripts = {
    "auth.sh" = <<-EOT
      #!/bin/sh
      aws ecr --region ${local.ecr_region} get-authorization-token --output text --query 'authorizationData[].authorizationToken' | base64 -d
    EOT
  }

  # Resource limits
  cpu_limit      = var.cpu_limit
  memory_limit   = var.memory_limit
  cpu_request    = var.cpu_request
  memory_request = var.memory_request

  # Logging and metrics
  log_level       = var.log_level
  metrics_enabled = var.metrics_enabled

  # Custom values using your exact structure
  custom_values = {
    serviceAccount = {
      name = var.service_account_name
    }

    authScripts = {
      enabled = true
      scripts = {
        "auth.sh" = <<-EOT
          #!/bin/sh
          aws ecr --region ${local.ecr_region} get-authorization-token --output text --query 'authorizationData[].authorizationToken' | base64 -d
        EOT
      }
    }

    config = {
      registries = [
        {
          name        = "ECR"
          api_url     = local.ecr_api_url
          prefix      = local.ecr_registry
          ping        = true
          insecure    = false
          credentials = "ext:/scripts/auth.sh"
          credsexpire = "10h"
        }
      ]
    }
  }

  tags = var.tags
}
