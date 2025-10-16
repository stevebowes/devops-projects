###############################################################################
# S3 Bucket for CodeBuild Cache
###############################################################################

module "codebuild_cache_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"
  
  bucket = "${local.cluster_name}-codebuild-cache-${local.aws_account_id}"
  
  # Enable versioning
  versioning = {
    enabled = true
  }
  
  # Enable server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  
  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
  # Enable force destroy for easier cleanup
  force_destroy = true
  
  tags = merge(
    var.tags,
    {
      Name    = "${local.cluster_name}-codebuild-cache"
      Project = "project-3-cicd"
    }
  )
}