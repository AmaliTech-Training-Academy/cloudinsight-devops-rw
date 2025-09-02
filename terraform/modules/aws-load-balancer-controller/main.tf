data "aws_iam_policy_document" "lbc_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole", "sts:TagSession"]
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.cluster_name}-aws-lbc"
  assume_role_policy = data.aws_iam_policy_document.lbc_trust.json
}

resource "aws_iam_policy" "this" {
  name        = "${var.cluster_name}-AWSLoadBalancerController"
  description = "AWS Load Balancer Controller policy"
  policy      = file("${path.module}/iam/AWSLoadBalancerController.json")
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_eks_pod_identity_association" "this" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account_name
  role_arn        = aws_iam_role.this.arn
}

locals {
  base_values = {
    clusterName = var.cluster_name
    region      = var.region
    vpcId       = var.vpc_id
    serviceAccount = {
      create = true
      name   = var.service_account_name
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
      }
    }
  }
  merged_values_yaml = yamlencode(local.base_values)
}

resource "helm_release" "this" {
  name             = var.service_account_name
  repository       = var.repository
  chart            = "aws-load-balancer-controller"
  version          = var.chart_version != "" ? var.chart_version : null
  namespace        = var.namespace
  create_namespace = false
  values           = [local.merged_values_yaml]
  depends_on       = [aws_eks_pod_identity_association.this]
}
