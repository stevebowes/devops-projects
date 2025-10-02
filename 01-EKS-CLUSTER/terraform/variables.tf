###############################################################################
# Required Variables
###############################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster. Used for resource naming and VPC tags."
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Cluster name must start with a letter and contain only alphanumeric characters and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

###############################################################################
# VPC Configuration
###############################################################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

###############################################################################
# EKS Cluster Configuration
###############################################################################

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.32"
  
  validation {
    condition     = can(regex("^1\\.(30|31|32|33)$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.30, 1.31, 1.32, or 1.33."
  }
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "authentication_mode" {
  description = "Authentication mode for the cluster. API_AND_CONFIG_MAP allows both EKS Access Entries and aws-auth ConfigMap"
  type        = string
  default     = "API_AND_CONFIG_MAP"
  
  validation {
    condition     = contains(["API", "API_AND_CONFIG_MAP", "CONFIG_MAP"], var.authentication_mode)
    error_message = "Authentication mode must be API, API_AND_CONFIG_MAP, or CONFIG_MAP."
  }
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Grant the cluster creator admin permissions automatically"
  type        = bool
  default     = true
}

variable "enable_cluster_logging" {
  description = "Enable EKS control plane logging (costs extra)"
  type        = bool
  default     = false
}

###############################################################################
# Node Group Configuration
###############################################################################

variable "node_instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
  
  validation {
    condition     = var.node_desired_size >= 1 && var.node_desired_size <= 10
    error_message = "Desired size must be between 1 and 10."
  }
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
  
  validation {
    condition     = var.node_min_size >= 1
    error_message = "Minimum size must be at least 1."
  }
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
  
  validation {
    condition     = var.node_max_size >= 1 && var.node_max_size <= 20
    error_message = "Maximum size must be between 1 and 20."
  }
}

###############################################################################
# Tagging
###############################################################################

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "development"
    Project     = "eks-devops"
  }
}