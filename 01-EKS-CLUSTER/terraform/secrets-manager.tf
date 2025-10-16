# IAM resources for External Secrets Operator
# These resources will be used by External Secrets Operator in Project 2
# to access application secrets that will be created in Project 3

# IAM policy for External Secrets Operator
# Note: This policy will be updated in Project 3 to include the actual secret ARNs
resource "aws_iam_policy" "external_secrets" {
  name        = "${var.cluster_name}-external-secrets-policy"
  description = "Policy for External Secrets Operator to read application secrets"
  path        = "/"
  
  # Initial policy - will be updated when secrets are created in Project 3
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
          # These will be updated in Project 3 when app secrets are created
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:dev/app/config*",
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:prod/app/config*",
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:ecr/credentials*"
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
      namespace_service_accounts = ["external-secrets:external-secrets"]
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