provider "aws" { region = var.region }

# Remote state for EKS cluster
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket  = "cloudinsight-tfstate"
    key     = "dev-staging/eks.tfstate"
    region  = var.region
    encrypt = true
  }
}
