locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Granular lifecycle policy optimized for v0.0.0-dev.1, v0.0.0-rc.1, v0.1.0 tagging strategy
  default_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 production releases (v*.*.* pattern)"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["v*.*.*"]
          countType      = "imageCountMoreThan"
          countNumber    = 20
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 10 release candidates (v*-rc.* pattern)"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["v*-rc.*"]
          countType      = "imageCountMoreThan"
          countNumber    = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Keep last 5 development builds (v*-dev.* pattern)"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["v*-dev.*"]
          countType      = "imageCountMoreThan"
          countNumber    = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 4
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Create ECR repositories for each service
resource "aws_ecr_repository" "repositories" {
  for_each = { for repo in var.repositories : repo.name => repo }

  name                 = each.value.name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(
    var.tags,
    {
      Name        = each.value.name
      Type        = each.value.type
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# Apply lifecycle policy to each repository
resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  for_each = aws_ecr_repository.repositories

  repository = each.value.name
  policy     = var.lifecycle_policy != "" ? var.lifecycle_policy : local.default_lifecycle_policy
}

# Create repository policy for cross-account access if needed
resource "aws_ecr_repository_policy" "repository_policy" {
  for_each = aws_ecr_repository.repositories

  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPushPull"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchDeleteImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings"
        ]
      }
    ]
  })
}
