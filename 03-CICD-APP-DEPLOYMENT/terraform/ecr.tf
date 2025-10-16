###############################################################################
# ECR Repository for Sample Application
###############################################################################

resource "aws_ecr_repository" "sample_app" {
  name                 = "${local.cluster_name}-sample-app"
  image_tag_mutability = "IMMUTABLE"  # Prevent tag overwrites
  force_delete         = true         # Allow cleanup during destroy

  # Enable image scanning on push
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    var.tags,
    {
      Name    = "${local.cluster_name}-sample-app-ecr"
      Project = "project-3-cicd"
    }
  )
}

###############################################################################
# ECR Lifecycle Policy
###############################################################################

resource "aws_ecr_lifecycle_policy" "sample_app" {
  repository = aws_ecr_repository.sample_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 5 development images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev-", "latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}