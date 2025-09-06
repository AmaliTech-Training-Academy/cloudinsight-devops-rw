# EKS with RDS IAM Authentication - Terraform Configuration

A complete Terraform configuration for setting up Amazon EKS with PostgreSQL RDS using IAM database authentication. This setup provides secure, password-less database access for your Kubernetes applications.

## Architecture Overview

This configuration creates:
- RDS PostgreSQL instance with IAM authentication enabled
- IAM roles and policies for database access
- EKS Pod Identity associations
- Kubernetes service accounts and deployments
- Database initialization job

## 1. RDS Instance with IAM Authentication Enabled

```hcl
resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  
  tags = {
    Name = "${var.cluster_name}-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.cluster_name}-rds-"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]  # Only EKS nodes
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.cluster_name}-postgres"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type         = "gp3"
  storage_encrypted    = true
  
  db_name  = "myapp"
  username = "postgres"
  password = "temporary-password"  # Will be changed to IAM auth
  
  # CRITICAL: Enable IAM database authentication
  iam_database_authentication_enabled = true
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Sun:04:00-Sun:05:00"
  
  skip_final_snapshot = true  # For demo - set to false in production
  
  tags = {
    Name = "${var.cluster_name}-postgres"
  }
}
```

## 2. IAM Role for Database Access

```hcl
# IAM role that pods will assume for database access
resource "aws_iam_role" "db_access" {
  name = "${var.cluster_name}-db-access-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

# Policy allowing RDS connect with IAM auth
resource "aws_iam_role_policy" "db_access" {
  name = "db-access-policy"
  role = aws_iam_role.db_access.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.main.identifier}/myapp_user"
        ]
      }
    ]
  })
}
```

## 3. EKS Pod Identity Association

```hcl
resource "aws_eks_pod_identity_association" "db_access" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "default"
  service_account = "myapp-sa"
  role_arn        = aws_iam_role.db_access.arn
  
  tags = {
    Purpose = "Database access via IAM authentication"
  }
}
```

## 4. Kubernetes Service Account

```hcl
resource "kubernetes_service_account" "myapp" {
  metadata {
    name      = "myapp-sa"
    namespace = "default"
    
    # No annotations needed for Pod Identity (unlike IRSA)
    labels = {
      "app.kubernetes.io/name" = "myapp"
    }
  }
  
  depends_on = [aws_eks_cluster.main]
}
```

## 5. Application Deployment with IAM Auth

```hcl
resource "kubernetes_config_map" "db_config" {
  metadata {
    name      = "db-config"
    namespace = "default"
  }
  
  data = {
    DB_HOST     = aws_db_instance.main.endpoint
    DB_PORT     = "5432"
    DB_NAME     = aws_db_instance.main.db_name
    DB_USERNAME = "myapp_user"  # IAM database user (not master user)
    USE_IAM_AUTH = "true"
  }
}

resource "kubernetes_deployment" "myapp" {
  metadata {
    name      = "myapp"
    namespace = "default"
  }
  
  spec {
    replicas = 2
    
    selector {
      match_labels = {
        app = "myapp"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "myapp"
        }
      }
      
      spec {
        service_account_name = kubernetes_service_account.myapp.metadata[0].name
        
        container {
          name  = "myapp"
          image = "myapp:latest"
          
          env_from {
            config_map_ref {
              name = kubernetes_config_map.db_config.metadata[0].name
            }
          }
          
          env {
            name = "AWS_REGION"
            value = data.aws_region.current.name
          }
          
          # Health checks
          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
          
          readiness_probe {
            http_get {
              path = "/ready"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
          
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }
}
```

## 6. Database Initialization Job

```hcl
resource "kubernetes_job" "db_init" {
  metadata {
    name      = "db-init"
    namespace = "default"
  }
  
  spec {
    template {
      metadata {
        labels = {
          job = "db-init"
        }
      }
      
      spec {
        service_account_name = kubernetes_service_account.myapp.metadata[0].name
        restart_policy       = "OnFailure"
        
        container {
          name  = "db-init"
          image = "postgres:15"
          
          env_from {
            config_map_ref {
              name = kubernetes_config_map.db_config.metadata[0].name
            }
          }
          
          env {
            name = "PGPASSWORD"
            value = "temporary-password"  # Master user password for initial setup
          }
          
          command = ["/bin/bash"]
          args = [
            "-c",
            <<-EOT
            set -e
            echo "Creating IAM database user..."
            
            # Connect as master user to create IAM user
            psql -h $DB_HOST -p $DB_PORT -U postgres -d $DB_NAME << 'EOSQL'
            -- Create IAM-authenticated user
            CREATE USER myapp_user;
            
            -- Grant rds_iam role (required for IAM auth)
            GRANT rds_iam TO myapp_user;
            
            -- Grant application permissions
            GRANT CONNECT ON DATABASE myapp TO myapp_user;
            GRANT USAGE ON SCHEMA public TO myapp_user;
            GRANT CREATE ON SCHEMA public TO myapp_user;
            GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO myapp_user;
            GRANT SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO myapp_user;
            
            -- Set default privileges for future tables
            ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO myapp_user;
            ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, UPDATE ON SEQUENCES TO myapp_user;
            
            EOSQL
            
            echo "Database user setup complete!"
            EOT
          ]
        }
      }
    }
  }
  
  depends_on = [
    aws_db_instance.main,
    kubernetes_service_account.myapp
  ]
}
```

## 7. Data Sources

```hcl
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
```

## 8. Outputs

```hcl
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_user_arn" {
  description = "ARN of the IAM database user"
  value       = "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.main.identifier}/myapp_user"
}

output "iam_role_arn" {
  description = "ARN of the IAM role for database access"
  value       = aws_iam_role.db_access.arn
}
```

## Key Features

- **Secure Database Access**: Uses IAM authentication instead of passwords
- **Pod Identity Integration**: Leverages EKS Pod Identity for seamless role assumption
- **Network Security**: RDS is isolated in private subnets with restrictive security groups
- **Automated Setup**: Database initialization job creates required IAM users and permissions
- **Production Ready**: Includes proper resource limits, health checks, and backup configuration

## Important Notes

1. **IAM Database Authentication**: The RDS instance has `iam_database_authentication_enabled = true`
2. **Database User**: The application connects as `myapp_user`, not the master user
3. **Pod Identity**: Uses EKS Pod Identity instead of IRSA (no service account annotations needed)
4. **Security**: Database is only accessible from EKS nodes via security group rules
5. **Initialization**: The database job runs once to set up the IAM user and permissions

## Deployment

1. Ensure you have the required variables defined
2. Run `terraform init` and `terraform plan`
3. Apply with `terraform apply`
4. The database initialization job will automatically create the IAM user
5. Your application pods can now connect to RDS using IAM authentication