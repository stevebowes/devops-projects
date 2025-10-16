variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "eks_tfstate_bucket" {
  description = "S3 bucket containing Project 1 terraform state"
  type        = string
  # Example: "eks-poc-tfstate-123456789012"
}

variable "eks_tfstate_key" {
  description = "S3 key for Project 1 terraform state"
  type        = string
  default     = "eks-poc/dev/terraform.tfstate"
}

variable "github_repo_url" {
  description = "GitHub repository URL for the mono-repo"
  type        = string
  # Example: "https://github.com/username/devops-projects.git"
}

variable "github_token" {
  description = "GitHub Personal Access Token for webhook creation"
  type        = string
  sensitive   = true
  # Get from: GitHub → Settings → Developer settings → Personal access tokens
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "project-3-cicd"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}