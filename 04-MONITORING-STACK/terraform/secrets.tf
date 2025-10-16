# Generate random password for Grafana admin
resource "random_password" "grafana_admin" {
  length  = 32
  special = true
}

# Grafana admin password (for Project 4)
resource "aws_secretsmanager_secret" "grafana_admin" {
  name                    = "monitoring/grafana-admin-password"
  recovery_window_in_days = 7
  tags                    = merge(var.tags, { Project = "monitoring" })
}

resource "aws_secretsmanager_secret_version" "grafana_admin" {
  secret_id = aws_secretsmanager_secret.grafana_admin.id
  
  secret_string = jsonencode({
    password = random_password.grafana_admin.result
  })
}

# Outputs (marked sensitive)
output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = random_password.grafana_admin.result
  sensitive   = true
}