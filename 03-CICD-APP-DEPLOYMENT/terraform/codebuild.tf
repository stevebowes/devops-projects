###############################################################################
# CloudWatch Log Group for CodeBuild
###############################################################################

resource "aws_cloudwatch_log_group" "codebuild_sample_app" {
  name              = "/aws/codebuild/${local.cluster_name}-sample-app"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name    = "${local.cluster_name}-codebuild-logs"
      Project = "project-3-cicd"
    }
  )
}

###############################################################################
# CodeBuild Project
###############################################################################

resource "aws_codebuild_project" "sample_app" {
  name          = "${local.cluster_name}-sample-app-build"
  description   = "Build project for sample application"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 30  # minutes

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = module.codebuild_cache_bucket.s3_bucket_id
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = true  # Required for Docker builds

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = aws_ecr_repository.sample_app.repository_url
    }

    environment_variable {
      name  = "ECR_REPOSITORY_NAME"
      value = aws_ecr_repository.sample_app.name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.aws_account_id
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
      type  = "PLAINTEXT"
    }
  }

  source {
    type            = "GITHUB"
    location        = var.github_repo_url
    git_clone_depth = 1
    buildspec       = "03-CICD-APP-DEPLOYMENT/sample-app/buildspec.yml"

    git_submodules_config {
      fetch_submodules = false
    }
  }

  source_version = "main"

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild_sample_app.name
      stream_name = "build-log"
    }
  }

  tags = merge(
    var.tags,
    {
      Name    = "${local.cluster_name}-sample-app-build"
      Project = "project-3-cicd"
    }
  )

  depends_on = [
    aws_ecr_repository.sample_app,
    aws_iam_role.codebuild_role,
    aws_cloudwatch_log_group.codebuild_sample_app
  ]
}

###############################################################################
# CodeBuild Source Credential (GitHub Personal Access Token)
###############################################################################

resource "aws_codebuild_source_credential" "github" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_token
}

###############################################################################
# CodeBuild Webhook (GitHub integration)
###############################################################################

resource "aws_codebuild_webhook" "sample_app" {
  project_name = aws_codebuild_project.sample_app.name

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "refs/heads/main"
    }

    filter {
      type    = "FILE_PATH"
      pattern = "03-CICD-APP-DEPLOYMENT/sample-app/.*"
    }
  }

  depends_on = [
    aws_codebuild_project.sample_app,
    aws_codebuild_source_credential.github
  ]
}