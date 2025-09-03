# Extract registry information from the first repository
locals {
  sample_repo_url = values(aws_ecr_repository.repositories)[0].repository_url
  registry_domain = regex("^([^/]+)", local.sample_repo_url)[0]
  registry_region = regex("dkr\\.ecr\\.([^.]+)", local.registry_domain)[0]
  account_id      = regex("^([0-9]+)", local.registry_domain)[0]
}

# Repository URLs (main output)
output "repository_urls" {
  description = "Map of repository names to their URLs"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.repository_url
  }
}

# Registry information for ArgoCD Image Updater
output "registry_info" {
  description = "ECR registry information for ArgoCD Image Updater configuration"
  value = {
    registry_url    = "https://${local.registry_domain}"
    registry_domain = local.registry_domain
    region          = local.registry_region
    account_id      = local.account_id
  }
}

# Repositories by type (for different deployment strategies)
output "backend_repositories" {
  description = "Backend service repository URLs"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.repository_url
    if contains([for r in var.repositories : r.name if r.type == "backend"], name)
  }
}

output "frontend_repositories" {
  description = "Frontend service repository URLs"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.repository_url
    if contains([for r in var.repositories : r.name if r.type == "frontend"], name)
  }
}
