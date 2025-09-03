output "ecr_repository_urls" {
  description = "Map of ECR repository names to their URLs"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "Map of ECR repository names to their ARNs"
  value       = module.ecr.repository_arns
}

output "frontend_repositories" {
  description = "Frontend ECR repository URLs"
  value       = module.ecr.frontend_repositories
}

output "backend_repositories" {
  description = "Backend ECR repository URLs"
  value       = module.ecr.backend_repositories
}
