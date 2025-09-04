# Services configuration - one secret per service with multiple key-value pairs
project_name = "cloudinsight"
environment  = "dev-staging"
region       = "eu-west-1"

# Secrets Access IAM Configuration
services = [
  {
    name        = "frontend"
    secret_name = "frontend"
  },
  {
    name        = "user-service"
    secret_name = "user-service"
  },
  {
    name        = "cost-service"
    secret_name = "cost-service"
  },
  {
    name        = "metric-service"
    secret_name = "metric-service"
  },
  {
    name        = "anomaly-service"
    secret_name = "anomaly-service"
  },
  {
    name        = "forecast-service"
    secret_name = "forecast-service"
  },
  {
    name        = "notification-service"
    secret_name = "notification-service"
  }
]

tags = {
  Environment = "dev-staging"
  Project     = "cloudinsight"
  ManagedBy   = "Terraform"
}
