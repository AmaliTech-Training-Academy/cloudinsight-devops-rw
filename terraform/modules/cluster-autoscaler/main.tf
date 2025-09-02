data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ca_trust" {
  statement {
    sid    = "EKSClusterPodsAssumeRole"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole", "sts:TagSession"]
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  name               = "${var.cluster_name}-cluster-autoscaler-role"
  assume_role_policy = data.aws_iam_policy_document.ca_trust.json
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "AutoscalingRead"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:DescribeScalingActivities",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "ScalingActions"
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${var.cluster_name}-ClusterAutoscalerPolicy"
  description = "Permissions for Kubernetes Cluster Autoscaler"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account_name
  role_arn        = aws_iam_role.cluster_autoscaler.arn
}

locals {
  base_values = {
    # Ensure all generated resource names (Deployment, SA, etc.) become exactly the desired service_account_name so Pod Identity association matches
    fullnameOverride = var.service_account_name
    autoDiscovery = {
      clusterName = var.cluster_name
    }
    awsRegion = var.aws_region
    extraArgs = {
      balance-similar-node-groups   = true
      skip-nodes-with-system-pods   = false
      skip-nodes-with-local-storage = false
      logtostderr                   = true
      stderrthreshold               = "info"
      expander                      = "least-waste"
      scan-interval                 = "30s"
      aws-use-static-instance-list  = true
    }
    # rbac key removed; using serviceAccount block directly per chart v9+ structure
    serviceAccount = {
      create = true
      name   = var.service_account_name
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler.arn
      }
    }
    serviceMonitor = { enabled = false }
  }
  merged_values_yaml = yamlencode(local.base_values)
}

resource "helm_release" "cluster_autoscaler" {
  name             = "cluster-autoscaler"
  repository       = var.repository
  chart            = "cluster-autoscaler"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = false

  values = [local.merged_values_yaml]

  depends_on = [aws_eks_pod_identity_association.cluster_autoscaler]
}
