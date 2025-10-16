terraform {
  required_version = ">= 1.5.7"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.95.0, < 6.0.0"
    }
  }
  
  backend "s3" {
    # Configure via init command:
    # terraform init -backend-config="bucket=${TF_STATE_BUCKET}" \
    #                -backend-config="key=cicd-app-deployment/terraform.tfstate" \
    #                -backend-config="region=${AWS_REGION}"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.tags
  }
}

# Data source to get current AWS account
data "aws_caller_identity" "current" {}

# Data source to reference Project 1 terraform state
data "terraform_remote_state" "eks" {
  backend = "s3"
  
  config = {
    bucket = var.eks_tfstate_bucket
    key    = var.eks_tfstate_key
    region = var.aws_region
  }
}

# Local values from Project 1
locals {
  cluster_name   = data.terraform_remote_state.eks.outputs.cluster_name
  aws_account_id = data.aws_caller_identity.current.account_id
}