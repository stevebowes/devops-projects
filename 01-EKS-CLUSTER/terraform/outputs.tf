###############################################################################
# Cluster Outputs
###############################################################################

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = module.eks.cluster_version
}

###############################################################################
# Node Group Outputs
###############################################################################

output "node_group_id" {
  description = "EKS node group ID"
  value       = module.eks.eks_managed_node_groups["main"].node_group_id
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = module.eks.eks_managed_node_groups["main"].node_group_status
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}

###############################################################################
# VPC Outputs
###############################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

###############################################################################
# kubectl Configuration Command
###############################################################################

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

###############################################################################
# Region and Account
###############################################################################

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# ===================================
# External Secrets IAM Outputs
# ===================================

output "external_secrets_policy_arn" {
  description = "ARN of the IAM policy for External Secrets Operator"
  value       = aws_iam_policy.external_secrets.arn
}

output "external_secrets_role_arn" {
  description = "ARN of the IAM role for External Secrets Operator (IRSA)"
  value       = module.external_secrets_irsa.iam_role_arn
}

output "external_secrets_role_name" {
  description = "Name of the IAM role for External Secrets Operator"
  value       = module.external_secrets_irsa.iam_role_name
}

# ===================================
# AWS Load Balancer Controller IAM Outputs
# ===================================

output "aws_load_balancer_controller_policy_arn" {
  description = "ARN of the IAM policy for AWS Load Balancer Controller"
  value       = aws_iam_policy.aws_load_balancer_controller.arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller (IRSA)"
  value       = module.aws_load_balancer_controller_irsa.iam_role_arn
}

output "aws_load_balancer_controller_role_name" {
  description = "Name of the IAM role for AWS Load Balancer Controller"
  value       = module.aws_load_balancer_controller_irsa.iam_role_name
}