# AWS Secrets Manager resources for External Secrets Operator
# These secrets will be used by applications in Project 2

# Development environment secret
resource "aws_secretsmanager_secret" "dev_app_config" {
  name        = "dev/app/config"
  description = "Development application configuration"
  
  recovery_window_in_days = 0  # Immediate deletion for dev/test
  
  tags = merge(
    var.tags,
    {
      Environment = "development"
      Application = "sample-app"
      ManagedBy   = "terraform"
    }
  )
}

# Production environment secret
resource "aws_secretsmanager_secret" "prod_app_config" {
  name        = "prod/app/config"
  description = "Production application configuration"
  
  recovery_window_in_days = 7  # 7-day recovery window for production
  
  tags = merge(
    var.tags,
    {
      Environment = "production"
      Application = "sample-app"
      ManagedBy   = "terraform"
    }
  )
}

# IAM policy for External Secrets Operator
resource "aws_iam_policy" "external_secrets" {
  name        = "${var.cluster_name}-external-secrets-policy"
  description = "Policy for External Secrets Operator to read application secrets"
  path        = "/"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.dev_app_config.arn,
          aws_secretsmanager_secret.prod_app_config.arn
        ]
      }
    ]
  })
  
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-external-secrets-policy"
    }
  )
}

# IAM role for External Secrets Operator (IRSA)
module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.60"
  
  role_name = "${var.cluster_name}-external-secrets"
  
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["monitoring:external-secrets"]
    }
  }
  
  role_policy_arns = {
    external_secrets = aws_iam_policy.external_secrets.arn
  }
  
  # Explicit dependency to ensure EKS cluster is created first
  depends_on = [module.eks]
  
  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-external-secrets-irsa"
    }
  )
}
