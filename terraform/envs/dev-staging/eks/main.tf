locals {
  base_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Stack       = "eks"
  }, var.tags)
}

# Placeholder output until EKS resources are added.
output "placeholder" { value = "eks stack initialized (no resources yet)" }
