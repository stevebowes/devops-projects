###############################################################################
# IAM Role for CodeBuild
###############################################################################

# Create IAM role for CodeBuild with proper trust policy
resource "aws_iam_role" "codebuild_role" {
  name = "${local.cluster_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name    = "${local.cluster_name}-codebuild-role"
      Project = "project-3-cicd"
    }
  )
}

# Attach CloudWatch Logs policy
resource "aws_iam_role_policy_attachment" "codebuild_cloudwatch" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

###############################################################################
# IAM Policy for ECR and S3 Access
###############################################################################

resource "aws_iam_role_policy" "codebuild_ecr_s3" {
  name = "${local.cluster_name}-codebuild-ecr-s3-policy"
  role = aws_iam_role.codebuild_role.name

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
      },
    ]
  })
}