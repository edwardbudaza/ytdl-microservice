resource "azurerm_resource_group" "main" {
  name     = "rg-${var.app_name}-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.app_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.app_name}-${var.environment}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}

resource "azurerm_container_app" "main" {
  name                         = "ca-${var.app_name}-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  template {
    container {
      name   = var.app_name
      image  = "${var.dockerhub_username}/${var.app_name}:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "AWS_BUCKET_NAME"
        value = var.aws_bucket_name
      }

      env {
        name  = "AWS_REGION"
        value = "us-east-2"
      }

      env {
        name  = "AWS_ACCESS_KEY_ID"
        value = var.aws_access_key_id
      }

      env {
        name        = "AWS_SECRET_ACCESS_KEY"
        secret_name = "aws-secret-key"
      }

      env {
        name        = "API_KEY"
        secret_name = "api-key"
      }

      env { 
        name = "RATE_LIMIT_REQUESTS"     
        value = "100" 
      }
      
      env { 
        name = "RATE_LIMIT_WINDOW"       
        value = "3600" 
      }

      env { 
        name = "MAX_FILE_SIZE_MB"        
        value = "500" 
      }

      env { 
        name = "COOKIE_FILE_PATH"        
        value = "/app/cookies/youtube_cookies.txt" 
      }

      env { 
        name = "PYTHONDONTWRITEBYTECODE" 
        value = "1" 
      }

      env { 
        name = "PYTHONUNBUFFERED"        
        value = "1" 
      }
    }

    min_replicas = 0
    max_replicas = 1
  }

  secret {
    name  = "aws-secret-key"
    value = var.aws_secret_access_key
  }

  secret {
    name  = "api-key"
    value = var.api_key
  }

  secret {
    name  = "dockerhub-password"
    value = var.dockerhub_password
  }

  registry {
    server              = "docker.io"
    username            = var.dockerhub_username
    password_secret_name = "dockerhub-password"
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 8000

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = {
    Environment = var.environment
    Application = var.app_name
  }
}
