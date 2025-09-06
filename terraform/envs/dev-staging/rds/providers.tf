provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      CreatedBy   = "devops-team"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is run
    args = ["eks", "get-token", "--cluster-name", "${var.project_name}-${var.environment}"]
  }
}

# Data source to get EKS cluster info for Kubernetes provider
data "aws_eks_cluster" "cluster" {
  name = "${var.project_name}-${var.environment}"
}