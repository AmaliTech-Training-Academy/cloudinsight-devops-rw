provider "aws" { region = var.region }

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket  = "cloudinsight-tfstate"
    key     = "dev-staging/eks.tfstate"
    region  = var.region
    encrypt = true
  }
}

data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket  = "cloudinsight-tfstate"
    key     = "dev-staging/networking.tfstate"
    region  = var.region
    encrypt = true
  }
}

data "aws_eks_cluster_auth" "this" { name = data.terraform_remote_state.eks.outputs.cluster_name }

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.this.token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}
