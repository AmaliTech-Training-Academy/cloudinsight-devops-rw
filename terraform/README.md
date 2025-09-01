# Terraform Infrastructure

Focus (current stage): Core networking (VPC + public/private subnets) with remote state & split state stacks (networking + eks placeholder) for dev-staging.

Structure:

bootstrap/ # Creates S3 bucket + DynamoDB table for remote state
envs/ # dev-staging stacks (networking/, eks/)
modules/ # Reusable modules (vpc for now)

Remote State Backend (region eu-west-1 by default):

- S3 Bucket: cloudinsight-tfstate (versioned & encrypted)
- DynamoDB Table: cloudinsight-tf-locks (state locking)
- State keys: <env>/terraform.tfstate

Variable Values:
All variable values are supplied via automatically loaded terraform.tfvars files (bootstrap/terraform.tfvars and envs/dev-staging/terraform.tfvars). No variable blocks contain defaults.

Usage:

1. Bootstrap backend (only once):
   cd terraform/bootstrap
   terraform init
   terraform apply -auto-approve
2. Deploy networking stack:
   cd ../envs/dev-staging/networking
   terraform init -backend-config=backend.hcl
   terraform plan # terraform.tfvars auto-loaded
   terraform apply
3. Initialize eks stack (placeholder):
   cd ../eks
   terraform init -backend-config=backend.hcl
   terraform plan

Each stack defines a different state key (dev-staging/networking.tfstate, dev-staging/eks.tfstate) but shares the same S3 bucket & DynamoDB lock table.

Outputs:

Networking stack:

- vpc_id
- public_subnet_ids
- private_subnet_ids

EKS stack:

- placeholder

Next steps (planned, not implemented yet):

- Internet Gateway + NAT Gateways + Route Tables (networking stack)
- Security Groups & Network ACLs
- Add EKS resources (cluster, node groups, addons) to eks stack
- Potential split into separate dev & staging later (duplicate stack dirs)
- Parameterize CIDR blocks via tfvars instead of inline values
