# General Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev-staging"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloudinsight"
}

# Database Configuration
variable "database_name" {
  description = "Database name"
  type        = string
  default     = "cloudinsight"
}

variable "master_username" {
  description = "Master database username"
  type        = string
  default     = "postgres"
}

variable "master_password" {
  description = "Master database password"
  type        = string
  sensitive   = true
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# Storage Configuration
variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage in GB"
  type        = number
  default     = 100
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

# Backup Configuration
variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion (dev/staging only)"
  type        = bool
  default     = true
}

# Monitoring
variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval"
  type        = number
  default     = 60
}

# IAM Database Users
variable "iam_database_users" {
  description = "List of IAM database users"
  type        = list(string)
  default     = ["cloudinsight_user", "readonly_user"]
}

# Kubernetes Configuration
variable "kubernetes_namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "default"
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account name"
  type        = string
  default     = "cloudinsight-sa"
}