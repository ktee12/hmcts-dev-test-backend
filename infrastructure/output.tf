output "resource_group_name" {
  description = "Name of the Azure resource group."
  value       = azurerm_resource_group.main.name
}

output "container_app_name" {
  description = "Name of the Azure Container App."
  value       = azurerm_container_app.application.name
}

output "container_app_url" {
  description = "Public HTTPS URL of the Azure Container App."
  value       = "https://${azurerm_container_app.application.latest_revision_fqdn}"
}

output "postgresql_server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "database_name" {
  description = "Name of the PostgreSQL application database."
  value       = azurerm_postgresql_flexible_server_database.application.name
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault."
  value       = azurerm_key_vault.main.name
}

output "managed_identity_client_id" {
  description = "Client ID of the application managed identity."
  value       = azurerm_user_assigned_identity.application.client_id
}