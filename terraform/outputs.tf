############################################################
# outputs.tf — Useful outputs for debugging/deployment
############################################################

output "resource_group_name" {
  description = "Resource Group name"
  value       = azurerm_resource_group.rg.name
}

output "function_app_name" {
  description = "Azure Function App name"
  value       = azurerm_linux_function_app.func.name
}

output "function_app_default_hostname" {
  description = "Function App default hostname"
  value       = azurerm_linux_function_app.func.default_hostname
}

output "cosmos_endpoint" {
  description = "Cosmos DB endpoint"
  value       = azurerm_cosmosdb_account.cosmos.endpoint
}

output "cosmos_primary_key" {
  description = "Cosmos DB primary key (sensitive)"
  value       = azurerm_cosmosdb_account.cosmos.primary_key
  sensitive   = true
}

output "cosmos_db_name" {
  description = "Cosmos DB database name"
  value       = azurerm_cosmosdb_sql_database.db.name
}

output "cosmos_container_name" {
  description = "Cosmos DB container name"
  value       = azurerm_cosmosdb_sql_container.container.name
}
