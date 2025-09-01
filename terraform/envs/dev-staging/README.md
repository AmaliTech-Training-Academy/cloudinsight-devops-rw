# dev-staging Stacks

This environment is split into multiple Terraform state stacks that share the same remote backend (S3 bucket + DynamoDB table) but use different state keys.

Stacks (current):

- networking: VPC + subnets (public/private) only
- eks: Placeholder (no resources yet)

Remote state key pattern:
dev-staging/<stack>.tfstate

See each subfolder for backend.hcl and terraform.tfvars.
