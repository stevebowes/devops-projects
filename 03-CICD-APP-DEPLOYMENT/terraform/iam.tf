###############################################################################
# IAM Role for CodeBuild
###############################################################################

module "codebuild_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"
  
  create_role = true
  role_name   = "${local.cluster_name}-codebuild-role"
  
  trusted_role_services = [
    "codebuild.amazonaws.com"
  ]
  
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
  
  tags = merge(
    var.tags,
    {
      Name    = "${local.cluster_name}-codebuild-role"
      Project = "project-3-cicd"
    }
  )
}

###############################################################################
# IAM Policy for ECR and S3 Access
###############################################################################

resource "aws_iam_role_policy" "codebuild_ecr_s3" {
  name = "${local.cluster_name}-codebuild-ecr-s3-policy"
  role = module.codebuild_role.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.codebuild_cache_bucket.s3_bucket_arn,
          "${module.codebuild_cache_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}