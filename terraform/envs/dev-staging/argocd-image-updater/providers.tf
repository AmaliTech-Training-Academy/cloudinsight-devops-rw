provider "aws" { region = var.region }

# Use EKS remote state from main.tf for cluster auth
data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.this.token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
}

provider "helm" {
  kubernetes {
    # Expand the path here where function calls are allowed
    config_path = pathexpand(var.kubeconfig_path)
  }
}
