output "repository_urls" {
  description = "Map of repository names to their URLs"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of repository names to their ARNs"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.arn
  }
}

output "repository_registry_ids" {
  description = "Map of repository names to their registry IDs"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.registry_id
  }
}

output "repository_names" {
  description = "List of repository names"
  value       = [for repo in aws_ecr_repository.repositories : repo.name]
}

output "frontend_repositories" {
  description = "Map of frontend repository names to their URLs"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.repository_url
    if contains([for r in var.repositories : r.name if r.type == "frontend"], name)
  }
}

output "backend_repositories" {
  description = "Map of backend repository names to their URLs"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.repository_url
    if contains([for r in var.repositories : r.name if r.type == "backend"], name)
  }
}
