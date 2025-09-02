locals {
  name = "${var.project_name}-${var.environment}"
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "cluster" {
  name               = "${local.name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "eks_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Attach managed AmazonEKSClusterPolicy
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = local.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]

  tags = var.tags
}

output "cluster_name" { value = aws_eks_cluster.this.name }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "cluster_version" { value = aws_eks_cluster.this.version }
output "cluster_arn" { value = aws_eks_cluster.this.arn }
output "cluster_certificate_authority_data" { value = aws_eks_cluster.this.certificate_authority[0].data }

# =====================================
# Worker Nodes (Managed Node Group)
# =====================================

data "aws_iam_policy_document" "node_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "node" {
  name               = "${local.name}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  version        = var.cluster_version
  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types

  scaling_config {
    min_size     = var.node_min_size
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = var.node_max_unavailable
  }

  labels = var.node_labels

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  tags = var.tags
}

output "node_group_name" { value = aws_eks_node_group.general.node_group_name }
output "node_role_arn" { value = aws_iam_role.node.arn }
