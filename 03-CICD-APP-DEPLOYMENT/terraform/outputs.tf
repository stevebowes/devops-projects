###############################################################################
# ECR Outputs
###############################################################################

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.sample_app.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.sample_app.arn
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.sample_app.name
}

###############################################################################
# CodeBuild Outputs
###############################################################################

output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.sample_app.name
}

output "codebuild_project_arn" {
  description = "CodeBuild project ARN"
  value       = aws_codebuild_project.sample_app.arn
}

output "codebuild_role_arn" {
  description = "CodeBuild IAM role ARN"
  value       = aws_iam_role.codebuild_role.arn
}

output "codebuild_webhook_url" {
  description = "CodeBuild webhook URL for GitHub"
  value       = aws_codebuild_webhook.sample_app.payload_url
}


###############################################################################
# S3 Outputs
###############################################################################

output "codebuild_cache_bucket_name" {
  description = "CodeBuild cache S3 bucket name"
  value       = module.codebuild_cache_bucket.s3_bucket_id
}

output "codebuild_cache_bucket_arn" {
  description = "CodeBuild cache S3 bucket ARN"
  value       = module.codebuild_cache_bucket.s3_bucket_arn
}

###############################################################################
# Helper Commands
###############################################################################

output "docker_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.sample_app.repository_url}"
}

output "kubectl_config_command" {
  description = "Command to configure kubectl (from Project 1)"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${local.cluster_name}"
}

###############################################################################
# Secrets Outputs (Sensitive)
###############################################################################

output "dev_app_config_secret_arn" {
  description = "ARN of the development app config secret"
  value       = aws_secretsmanager_secret.dev_app_config.arn
}

output "prod_app_config_secret_arn" {
  description = "ARN of the production app config secret"
  value       = aws_secretsmanager_secret.prod_app_config.arn
}

output "dev_api_key" {
  description = "Development API key (sensitive)"
  value       = random_password.dev_api_key.result
  sensitive   = true
}

output "prod_api_key" {
  description = "Production API key (sensitive)"
  value       = random_password.prod_api_key.result
  sensitive   = true
}

output "dev_jwt_secret" {
  description = "Development JWT secret (sensitive)"
  value       = random_password.dev_jwt_secret.result
  sensitive   = true
}

output "prod_jwt_secret" {
  description = "Production JWT secret (sensitive)"
  value       = random_password.prod_jwt_secret.result
  sensitive   = true
}

output "ecr_credentials_secret_arn" {
  description = "ECR credentials secret ARN"
  value       = aws_secretsmanager_secret.ecr_credentials.arn
}