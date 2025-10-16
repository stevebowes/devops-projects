# Generate random password for OpenSearch admin
resource "random_password" "opensearch_admin" {
  length  = 32
  special = true
}

# OpenSearch admin password (for Project 5)
resource "aws_secretsmanager_secret" "opensearch_admin" {
  name                    = "logging/opensearch-admin-password"
  recovery_window_in_days = 7
  tags                    = merge(var.tags, { Project = "logging" })
}

resource "aws_secretsmanager_secret_version" "opensearch_admin" {
  secret_id = aws_secretsmanager_secret.opensearch_admin.id
  
  secret_string = jsonencode({
    "admin-password" = random_password.opensearch_admin.result
  })
}

# Outputs (marked sensitive)
output "opensearch_admin_password" {
  description = "OpenSearch admin password"
  value       = random_password.opensearch_admin.result
  sensitive   = true
}