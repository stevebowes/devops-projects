# Generate random passwords for application secrets
resource "random_password" "dev_api_key" {
  length  = 32
  special = true
}

resource "random_password" "prod_api_key" {
  length  = 32
  special = true
}

resource "random_password" "dev_jwt_secret" {
  length  = 32
  special = true
}

resource "random_password" "prod_jwt_secret" {
  length  = 32
  special = true
}

# Development application secrets
resource "aws_secretsmanager_secret" "dev_app_config" {
  name                    = "dev/app/config"
  recovery_window_in_days = 7
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "dev_app_config" {
  secret_id = aws_secretsmanager_secret.dev_app_config.id
  
  secret_string = jsonencode({
    DATABASE_URL = "postgresql://localhost:5432/dev_database"
    API_KEY      = random_password.dev_api_key.result
    JWT_SECRET   = random_password.dev_jwt_secret.result
    LOG_LEVEL    = "debug"
  })
}

# Production application secrets
resource "aws_secretsmanager_secret" "prod_app_config" {
  name                    = "prod/app/config"
  recovery_window_in_days = 30
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "prod_app_config" {
  secret_id = aws_secretsmanager_secret.prod_app_config.id
  
  secret_string = jsonencode({
    DATABASE_URL = "postgresql://prod-db.example.com:5432/prod_database"
    API_KEY      = random_password.prod_api_key.result
    JWT_SECRET   = random_password.prod_jwt_secret.result
    LOG_LEVEL    = "info"
  })
}