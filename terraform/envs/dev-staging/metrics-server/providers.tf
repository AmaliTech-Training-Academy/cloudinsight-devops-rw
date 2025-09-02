provider "aws" { region = var.region }

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

data "aws_eks_cluster_auth" "this" { name = data.terraform_remote_state.eks.outputs.cluster_name }
data "aws_eks_node_group" "general" {
  cluster_name    = data.terraform_remote_state.eks.outputs.cluster_name
  node_group_name = data.terraform_remote_state.eks.outputs.node_group_name
}

provider "kubernetes" {
  # Using remote state outputs for endpoint & CA to avoid extra cluster data lookup.
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.this.token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
}

provider "helm" {
  kubernetes {
    # Use kubeconfig path (explicit) instead of embedding cluster connection again.
    # Ensure you've run: aws eks update-kubeconfig --name ${data.terraform_remote_state.eks.outputs.cluster_name} --region ${var.region}
    config_path = var.kubeconfig_path
  }
}
