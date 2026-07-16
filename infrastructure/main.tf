data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_password" "database" {
  length           = 24
  special          = true
  override_special = "!#%*-_=+"
}

locals {
  resource_prefix = "${var.service_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      environment = var.environment
    }
  )
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_user_assigned_identity" "application" {
  name                = "id-${local.resource_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.environment}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "database_password" {
  name         = "database-password"
  value        = random_password.database.result
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_role_assignment" "application_key_vault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.application.principal_id
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${local.resource_prefix}-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "16"
  administrator_login    = var.database_admin_username
  administrator_password = random_password.database.result
  storage_mb             = var.database_storage_mb
  sku_name               = var.database_sku_name

  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = true

  tags = local.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "application" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.resource_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${local.resource_prefix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = local.common_tags
}

resource "azurerm_container_app" "application" {
  name                         = "ca-${local.resource_prefix}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  identity {
    type = "UserAssigned"

    identity_ids = [
      azurerm_user_assigned_identity.application.id
    ]
  }

  secret {
    name                = "database-password"
    key_vault_secret_id = azurerm_key_vault_secret.database_password.versionless_id
    identity            = azurerm_user_assigned_identity.application.id
  }

  template {
    min_replicas = 1
    max_replicas = 3

    container {
      name   = "application"
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.main.fqdn
      }

      env {
        name  = "DB_PORT"
        value = "5432"
      }

      env {
        name  = "DB_NAME"
        value = azurerm_postgresql_flexible_server_database.application.name
      }

      env {
        name  = "DB_USER_NAME"
        value = var.database_admin_username
      }

      env {
        name        = "DB_PASSWORD"
        secret_name = "database-password"
      }

      env {
        name  = "DB_OPTIONS"
        value = "?sslmode=require"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 4000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  depends_on = [
    azurerm_role_assignment.application_key_vault_secrets_user
  ]

  tags = local.common_tags
}