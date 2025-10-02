# Required: Unique name for your EKS cluster
cluster_name = "eks-cluster"

# AWS Region
aws_region = "us-east-1"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Kubernetes Version (1.32 recommended for stability)
kubernetes_version = "1.32"

# Node Group Configuration
node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 2
node_max_size       = 4

# Enable control plane logging (costs extra ~$0.50/GB)
enable_cluster_logging = false

# Tags for all resources
tags = {
  Terraform   = "true"
  Environment = "development"
  Project     = "eks-devops-project1"
  ManagedBy   = "terraform"
}