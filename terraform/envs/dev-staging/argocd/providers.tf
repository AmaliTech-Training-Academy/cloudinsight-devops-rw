variable "region" { type = string }
variable "kubeconfig_path" {
  type = string
  # Can't call functions in a variable default; use literal and expand later in provider block.
  default = "~/.kube/config"
}
variable "project_name" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }

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

data "aws_eks_cluster_auth" "this" { name = data.terraform_remote_state.eks.outputs.cluster_name }

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
