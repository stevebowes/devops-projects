terraform {
  required_version = ">= 1.5.7"
  
  backend "s3" {
    # Backend configuration will be provided via -backend-config flags
    # during terraform init
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.95.0, < 6.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Get current AWS account information
data "aws_caller_identity" "current" {}

# Get AWS partition information
data "aws_partition" "current" {}

# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

###############################################################################
# VPC Module
# Creates networking infrastructure including subnets, NAT gateways, and IGW
###############################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = [cidrsubnet(var.vpc_cidr, 8, 10), cidrsubnet(var.vpc_cidr, 8, 11)]
  public_subnets  = [cidrsubnet(var.vpc_cidr, 8, 0), cidrsubnet(var.vpc_cidr, 8, 1)]

  enable_nat_gateway   = true
  single_nat_gateway   = false  # Multi-AZ NAT for high availability
  enable_dns_hostnames = true
  enable_dns_support   = true

  # CRITICAL: Required tags for EKS subnet discovery
  # These tags allow EKS to identify which subnets to use for different resources
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )

}

###############################################################################
# EKS Module
# Creates the EKS cluster, node groups, and required IAM roles
###############################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  # Cluster configuration
  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version
  
  # Networking
  vpc_id                   = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # API endpoint access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  # CRITICAL: Grant cluster creator admin access
  # Without this, you may not be able to access your cluster
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  # Explicit dependency to ensure VPC is created first and destroyed last
  depends_on = [module.vpc]

  # Control plane logging (optional, costs extra)
  # Note: Logging configuration may need to be adjusted for v21.x
  # enabled_cluster_log_types = var.enable_cluster_logging ? [
  #   "api",
  #   "audit", 
  #   "authenticator",
  #   "controllerManager",
  #   "scheduler"
  # ] : []

  # EKS Managed Addons
  # These are automatically updated and managed by AWS
  cluster_addons = {
    vpc-cni = {
      most_recent = true
      before_compute = true  # Install before node groups
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  # EKS Managed Node Group
  eks_managed_node_groups = {
    main = {
      name = "${var.cluster_name}-nodes"
      
      # Use Amazon Linux 2023 (AL2 reaches EOL Nov 26, 2025)
      ami_type = "AL2023_x86_64_STANDARD"
      
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      # Scaling configuration
      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Disk configuration
      disk_size = 20

      # Network configuration
      subnet_ids = module.vpc.private_subnets

      # IAM policies for nodes
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        # Note: For production, use IRSA for CNI policy instead of attaching to node role
      }

      tags = merge(
        var.tags,
        {
          "Name" = "${var.cluster_name}-node"
        }
      )
    }
  }

  tags = var.tags
}
